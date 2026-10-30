# Run with -Watch to keep copying changes until Ctrl+C. No files are deleted.
[CmdletBinding()]
param(
    [string]$Destination = 'C:\Users\glask\Documents\bulwark',
    [switch]$Watch,
    [ValidateRange(1, 3600)]
    [int]$IntervalSeconds = 5,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
$target = [IO.Path]::GetFullPath($Destination).TrimEnd('\')
if ($target -eq $source -or $target.StartsWith($source + '\', [StringComparison]::OrdinalIgnoreCase) -or $source.StartsWith($target + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Source and destination must be separate folders, neither inside the other.'
}
if (-not (Test-Path -LiteralPath (Join-Path $target '.git'))) {
    throw "Destination must be an existing Git checkout: $target"
}

# /E includes every mission folder; /XO avoids overwriting newer repository files.
# Deliberately omit /MIR and /PURGE to preserve Git metadata and repo-only files.
$copyArgs = @($source, $target, '/E', '/XO', '/R:2', '/W:1', '/NP', '/NJH', '/NJS',
    '/XD', '.git', '.codex', '.agents', '/XF', '.git')
if ($DryRun) { $copyArgs += '/L' }
do {
    & robocopy.exe @copyArgs
    if ($LASTEXITCODE -ge 8) {
        throw "Copy failed (robocopy exit code $LASTEXITCODE)."
    }
    if ($Watch) { Start-Sleep -Seconds $IntervalSeconds }
} while ($Watch)
# Robocopy codes 0 through 7 are successful outcomes.
exit 0
