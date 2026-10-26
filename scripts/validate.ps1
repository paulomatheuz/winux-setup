[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()][string]$ReportRoot,
    [ValidateNotNullOrEmpty()][string]$RepositoryRoot,
    [ValidateRange(1,3600)][int]$TimeoutSeconds = 180,
    [ValidateNotNullOrEmpty()]
    [ValidateSet('btop','configuration','device','fonts','komorebi','modules','powershell','rain','restore','starship','startup','visual-assets','whkd','windows-terminal','yasb')]
    [string[]]$Suites = @('btop','configuration','device','fonts','komorebi','modules','powershell','rain','restore','starship','startup','visual-assets','whkd','windows-terminal','yasb')
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSVersion -lt [version]'5.1') { throw 'Use Windows PowerShell 5.1 ou PowerShell 7 no Windows.' }
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$repository = Get-Item -LiteralPath $RepositoryRoot -ErrorAction Stop
if (-not $repository.PSIsContainer) { throw 'Informe a pasta do repositorio.' }
if (-not $ReportRoot) { $ReportRoot = Join-Path ([IO.Path]::GetTempPath()) 'winux-validation' }
$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N')
$runDirectory = Join-Path ([IO.Path]::GetFullPath($ReportRoot)) $runId
[IO.Directory]::CreateDirectory($runDirectory) | Out-Null
$reportPath = Join-Path $runDirectory 'summary.json'
$powerShell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$encoding = New-Object Text.UTF8Encoding($false)
function Save-ValidationReport {
    $temporary = $reportPath + '.tmp'
    try {
        [IO.File]::WriteAllText($temporary,(ConvertTo-Json -InputObject $report -Depth 8),$encoding)
        if ([IO.File]::Exists($reportPath)) { [IO.File]::Replace($temporary,$reportPath,[NullString]::Value) }
        else { [IO.File]::Move($temporary,$reportPath) }
    } finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
}
function Quote-ValidationArgument([string]$Value) {
    if ($Value.Contains('"')) { throw 'Caminho com aspas nao suportado.' }
    return '"' + ($Value -replace '(\\+)$','$1$1') + '"'
}
$report = [pscustomobject]@{
    SchemaVersion=1
    StartedUtc=[DateTime]::UtcNow.ToString('o')
    FinishedUtc=$null
    Status='Running'
    Scope='IsolatedTests'
    Selection=if ($PSBoundParameters.ContainsKey('Suites')) { 'SelectedSuites' } else { 'AllSuites' }
    PowerShellVersion=$PSVersionTable.PSVersion.ToString()
    PowerShellEdition=$PSVersionTable.PSEdition
    Is64BitProcess=[Environment]::Is64BitProcess
    RepositoryRoot=$repository.FullName
    SyntaxErrors=@()
    Suites=@()
}
Save-ValidationReport
foreach ($folder in @('scripts','tests','config')) {
    $path = Join-Path $repository.FullName $folder
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { continue }
    foreach ($file in @(Get-ChildItem -LiteralPath $path -Filter '*.ps1' -File -Recurse)) {
        $tokens=$null; $parseErrors=$null
        [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$parseErrors) | Out-Null
        foreach ($parseError in $parseErrors) {
            $report.SyntaxErrors += [pscustomobject]@{File=$file.FullName; Line=$parseError.Extent.StartLineNumber; Message=$parseError.Message}
        }
    }
}
foreach ($suite in @($Suites | Select-Object -Unique)) {
    $caseDirectory = Join-Path $runDirectory $suite
    [IO.Directory]::CreateDirectory($caseDirectory) | Out-Null
    $testPath = Join-Path $repository.FullName ('tests\' + $suite + '.tests.ps1')
    $stdout = Join-Path $caseDirectory 'stdout.log'
    $stderr = Join-Path $caseDirectory 'stderr.log'
    $entry = [pscustomobject]@{Name=$suite; Status='Running'; ExitCode=$null; TestSHA256=$null; DurationSeconds=$null; Stdout=$stdout; Stderr=$stderr; Error=$null}
    $report.Suites += $entry
    Save-ValidationReport
    Write-Host ('Verificando: ' + $suite)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $process = $null
    try {
        if (-not (Test-Path -LiteralPath $testPath -PathType Leaf)) { throw "Teste nao encontrado: $testPath" }
        $entry.TestSHA256 = (Get-FileHash -LiteralPath $testPath -Algorithm SHA256).Hash
        $arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' + (Quote-ValidationArgument $testPath) +
            ' -TestRoot ' + (Quote-ValidationArgument (Join-Path $caseDirectory 'workspace')) +
            ' -RepositoryRoot ' + (Quote-ValidationArgument $repository.FullName)
        $process = Start-Process -FilePath $powerShell -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        # Mantenha o handle aberto para ler ExitCode no Windows PowerShell 5.1.
        [void]$process.Handle
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            $process.WaitForExit()
            $entry.Status = 'TimedOut'
            $entry.Error = 'O teste excedeu o limite de tempo.'
        } else {
            $process.WaitForExit()
            $entry.ExitCode = $process.ExitCode
            $entry.Status = if ($process.ExitCode -eq 0) { 'Passed' } else { 'Failed' }
        }
    } catch {
        $entry.Status = 'Failed'
        $entry.Error = $_.Exception.Message
    } finally {
        if ($process) { $process.Dispose() }
        $timer.Stop()
        $entry.DurationSeconds = [Math]::Round($timer.Elapsed.TotalSeconds,3)
        Save-ValidationReport
    }
    Write-Host ($suite + ': ' + $entry.Status)
}
$report.FinishedUtc = [DateTime]::UtcNow.ToString('o')
$failed = @($report.Suites | Where-Object Status -ne 'Passed').Count
$report.Status = if ($failed -eq 0 -and $report.SyntaxErrors.Count -eq 0) { 'Passed' } else { 'Failed' }
Save-ValidationReport
Write-Host ('Resultado dos testes isolados: ' + $report.Status + '. Relatorio: ' + $reportPath)
if ($report.Status -ne 'Passed') { exit 1 }
