#Requires -Version 5.1
<#
.SYNOPSIS
  Local launcher for kimodo.cpp - generate motion or start the demo web UI.

.DESCRIPTION
  Double-click via Launch-Kimodo.bat, or run from PowerShell:
    powershell -ExecutionPolicy Bypass -File Launch-Kimodo.ps1 -Prompt "a person waving" -Frames 120 -Steps 50 -Seed 42
    powershell -ExecutionPolicy Bypass -File Launch-Kimodo.ps1 -Mode demo

  Tested on: VS Community 2026, Vulkan SDK 1.4.357.0, Go 1.27.1, Python 3.10 + huggingface_hub.
#>
param(
  [string]$Prompt = "a person walking forward enthusiastically and waving their right hand",
  [int]$Frames = 120,
  [int]$Steps = 50,
  [int]$Seed = 42,
  [ValidateSet("generate", "demo")]
  [string]$Mode = "generate",
  [string]$Model = "models/kimodo-soma-rp-v1.1-f32.gguf",
  [string]$TextBundle = "generated/llm2vec-text-bundle",
  [string]$OutDir = "output_motion",
  [string]$Addr = "127.0.0.1:8094"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $RepoRoot

# --- Vulkan SDK (needed at configure time; runtime uses system vulkan-1.dll) ---
if (-not $env:VULKAN_SDK -and (Test-Path -LiteralPath "C:\VulkanSDK\1.4.357.0")) {
  $env:VULKAN_SDK = "C:\VulkanSDK\1.4.357.0"
}
if ($env:VULKAN_SDK -and (Test-Path -LiteralPath "$env:VULKAN_SDK\Bin")) {
  $env:PATH = "$env:VULKAN_SDK\Bin;" + $env:PATH
}

# --- Native DLLs (ggml + kimodo) must be on PATH or kmd-*.exe fails to start ---
$env:PATH = "$RepoRoot\build\bin\Release;$RepoRoot\build\Release;" + $env:PATH

function Find-Python {
  $candidates = @(
    "D:\Program Files\Python310\python.exe",
    "C:\Program Files\Python310\python.exe",
    "C:\Python310\python.exe"
  )
  foreach ($p in $candidates) { if (Test-Path -LiteralPath $p) { return $p } }
  foreach ($c in @("py", "python", "python3")) {
    try { $hit = (Get-Command $c -ErrorAction Stop).Source; if ($hit) { return $hit } } catch {}
  }
  return $null
}

if ($Mode -eq "demo") {
  $genExe = Join-Path $RepoRoot "build\Release\kmd-generate.exe"
  if (-not (Test-Path -LiteralPath $genExe)) { throw "Missing $genExe. Build first: cmake --build build --config Release" }
  $somaRP = Join-Path $RepoRoot "models\kimodo-soma-rp-v1.1-f32.gguf"
  $textDir = Join-Path $RepoRoot "generated\llm2vec-text-bundle"
  $outDir = Join-Path $RepoRoot "demo-output"
  $demoArgs = @("-addr", $Addr, "-generator", $genExe, "-soma-rp-model", $somaRP, "-text-bundle", $textDir, "-output", $outDir)
  Write-Host "Starting demo at http://$Addr (Ctrl+C to stop)..."
  Write-Host "Note: only models with downloaded GGUFs are selectable; others correctly show coming soon."
  $demoExe = Join-Path $RepoRoot "demo\demo.exe"
  if (Test-Path -LiteralPath $demoExe) {
    & $demoExe @demoArgs
    exit $LASTEXITCODE
  }
  $go = $null
  try { $go = (Get-Command go -ErrorAction Stop).Source } catch {}
  if (-not $go -and (Test-Path -LiteralPath "C:\Program Files\Go\bin\go.exe")) { $go = "C:\Program Files\Go\bin\go.exe" }
  if (-not $go) { throw "Neither demo\demo.exe nor Go found. Re-download the package or install Go from https://go.dev/dl/." }
  & $go run ./demo @demoArgs
  exit $LASTEXITCODE
}

# --- generate mode ---
$gen = Join-Path $RepoRoot "build\Release\kmd-generate.exe"
if (-not (Test-Path -LiteralPath $gen)) { throw "Missing $gen. Build first: cmake --build build --config Release" }
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $Model))) { throw "Missing $Model. Run: python scripts/download_gguf_weights.py --model soma-rp-v1.1" }
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot "$TextBundle\layer-00.gguf"))) { throw "Text bundle incomplete at $TextBundle (need 35 files). Re-run the downloader." }

$python = Find-Python
if (-not $python) { throw "Python 3.10+ not found. Install it, then: python -m pip install huggingface_hub" }

$promptFile = Join-Path $RepoRoot "prompt.txt"
$Prompt | Out-File -FilePath $promptFile -Encoding utf8 -NoNewline
Write-Host "Prompt: $Prompt"

& $gen $Model $TextBundle $promptFile $Frames $Steps $Seed $OutDir
if ($LASTEXITCODE -ne 0) { throw "kmd-generate failed with exit code $LASTEXITCODE" }

& $python (Join-Path $RepoRoot "scripts/export_glb.py") --motion-dir (Join-Path $RepoRoot $OutDir) --output (Join-Path $RepoRoot "$OutDir/animation.glb")
if ($LASTEXITCODE -ne 0) { throw "export_glb.py failed with exit code $LASTEXITCODE" }

Write-Host ""
Write-Host "Done. Files in $OutDir\ :"
Get-ChildItem -LiteralPath (Join-Path $RepoRoot $OutDir) | Select-Object Name, Length | Format-Table -AutoSize
Write-Host "Import $OutDir\animation.glb into Blender/Unreal, or run demo mode: .\Launch-Kimodo.ps1 -Mode demo"
