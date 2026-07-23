$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath(
  (Join-Path -Path $PSScriptRoot -ChildPath '..')
)
$buildDirectory = [System.IO.Path]::GetFullPath(
  (Join-Path -Path $projectRoot -ChildPath 'build\web')
)
$publicDirectory = [System.IO.Path]::GetFullPath(
  (Join-Path -Path $projectRoot -ChildPath 'public')
)
$expectedPublicDirectory = [System.IO.Path]::GetFullPath(
  (Join-Path -Path $projectRoot -ChildPath 'public')
)

if (
  $publicDirectory -ne $expectedPublicDirectory -or
  -not $publicDirectory.StartsWith(
    $projectRoot + [System.IO.Path]::DirectorySeparatorChar,
    [System.StringComparison]::OrdinalIgnoreCase
  )
) {
  throw "Refusing to replace an unexpected directory: $publicDirectory"
}

Push-Location $projectRoot

try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get failed.'
  }

  flutter build web --release --base-href / --pwa-strategy=none
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter build web failed.'
  }

  if (-not (Test-Path -LiteralPath $buildDirectory -PathType Container)) {
    throw "Flutter web output was not created: $buildDirectory"
  }

  if (Test-Path -LiteralPath $publicDirectory) {
    Remove-Item -LiteralPath $publicDirectory -Recurse -Force
  }

  New-Item -ItemType Directory -Path $publicDirectory | Out-Null
  Copy-Item -Path (Join-Path $buildDirectory '*') `
    -Destination $publicDirectory `
    -Recurse `
    -Force

  $localBuildMarker = Join-Path $publicDirectory '.last_build_id'
  if (Test-Path -LiteralPath $localBuildMarker) {
    Remove-Item -LiteralPath $localBuildMarker -Force
  }

  Write-Host "Vercel bundle is ready: $publicDirectory"
} finally {
  Pop-Location
}
