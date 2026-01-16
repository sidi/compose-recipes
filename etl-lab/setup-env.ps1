<#  setup-env.ps1
    Creates required directories relative to the CURRENT WORKING DIRECTORY,
    then downloads postgresql-42.7.4.jar into data\nifi\data\

    Usage:
      pwsh -File .\setup-env.ps1
#>

# Be strict and fail fast on errors
$ErrorActionPreference = 'Stop'

# --- Configuration ---
$JarVersion = '42.7.4'
$JarName    = "postgresql-$JarVersion.jar"
$Url        = "https://repo1.maven.org/maven2/org/postgresql/postgresql/$JarVersion/$JarName"

# Base path = wherever this script is RUN FROM (not the script file location)
$Base = Get-Location

$Dirs = @(
  'data\db',
  'data\kafka',
  'data\nifi\data',
  'data\nifi\logs',
  'data\pgadmin',
  'data/prefect/sqlite',
  'data/prefect/runs'
)

Write-Host "Creating directories under: $($Base.Path)"
foreach ($rel in $Dirs) {
  $path = Join-Path -Path $Base -ChildPath $rel
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Write-Host "  + $rel"
  } else {
    Write-Host "  = $rel (exists)"
  }
}

# Destination for the JAR
$destDir  = Join-Path $Base 'data\nifi\data'
$destPath = Join-Path $destDir $JarName

# If file exists and is non-empty, skip download
if (Test-Path -LiteralPath $destPath -PathType Leaf) {
  $info = Get-Item -LiteralPath $destPath
  if ($info.Length -gt 0) {
    Write-Host "JAR already present: $($destPath)"
    exit 0
  }
}

Write-Host "Downloading $JarName ..."
# Use Invoke-WebRequest; -UseBasicParsing keeps compatibility with Windows PowerShell 5.1
try {
  Invoke-WebRequest -Uri $Url -OutFile $destPath -UseBasicParsing
}
catch {
  Write-Warning "Invoke-WebRequest failed: $($_.Exception.Message)"
  Write-Host "Trying BITS (Background Intelligent Transfer Service)..."
  # Fallback to BITS (available on most Windows)
  Start-BitsTransfer -Source $Url -Destination $destPath
}

# Verify file exists and is non-empty
if (-not (Test-Path -LiteralPath $destPath)) {
  throw "Download failed: file not found at $destPath"
}
if ((Get-Item -LiteralPath $destPath).Length -le 0) {
  throw "Download failed: file at $destPath is empty"
}

Write-Host "Saved: $destPath"
Write-Host "All done."
