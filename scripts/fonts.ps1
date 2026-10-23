function Get-WinuxInstalledFontNames {
    Add-Type -AssemblyName System.Drawing
    $collection = New-Object System.Drawing.Text.InstalledFontCollection
    try { $collection.Families | ForEach-Object { $_.Name } | Sort-Object -Unique }
    finally { $collection.Dispose() }
}

function Get-WinuxFontReport {
    param([AllowEmptyCollection()][string[]]$AvailableNames, [string]$CatalogPath)
    $ErrorActionPreference = 'Stop'
    if (-not $CatalogPath) { $CatalogPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'fonts.psd1' }
    if (-not $PSBoundParameters.ContainsKey('AvailableNames')) { $AvailableNames = @(Get-WinuxInstalledFontNames) }
    $catalog = Import-PowerShellDataFile -LiteralPath $CatalogPath
    foreach ($check in $catalog.Checks) {
        $matched = @($check.Aliases | Where-Object { $AvailableNames -contains $_ } | Select-Object -First 1)
        [pscustomobject]@{
            Usage = $check.Usage
            Package = $check.Package
            ConfiguredName = $check.ConfiguredName
            Available = ($matched.Count -gt 0)
            MatchedName = if ($matched.Count -gt 0) { $matched[0] } else { $null }
            Optional = [bool]$check.Optional
        }
    }
}
