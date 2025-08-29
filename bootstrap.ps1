<#  bootstrap.ps1
    One-shot: download latest Ubuntu 24.04 LTS Server ISO, verify SHA256, then create/boot VM via hyperv/create-vm.ps1
    Usage:
      .\bootstrap.ps1 -VMName lab
#>

param(
  [string]$VMName = "lab",
  [string]$Downloads = "$env:USERPROFILE\Downloads",
  [string]$ReleasesBase = "https://releases.ubuntu.com/noble"
)

# --- sanity: Hyper-V available?
if (-not (Get-Command Get-VM -ErrorAction SilentlyContinue)) {
  Write-Error "Hyper-V PowerShell not available. Run (as Admin), reboot, then re-run:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All"
  exit 1
}

# --- figure out latest 24.04.x live-server ISO from SHA256SUMS
$shaFile = Join-Path $Downloads "SHA256SUMS"
Invoke-WebRequest "$ReleasesBase/SHA256SUMS" -OutFile $shaFile -UseBasicParsing

# match 24.04(.x) live-server amd64 lines, pick highest x (or base)
$lines = Get-Content $shaFile | Where-Object { $_ -match 'ubuntu-24\.04(\.\d+)?-live-server-amd64\.iso' }
if (-not $lines) { Write-Error "Could not find ubuntu-24.04 live-server entry in SHA256SUMS."; exit 1 }

$isoName = ($lines | ForEach-Object {
  if ($_ -match '(?<hash>^[0-9a-f]{64}).*?(?<name>ubuntu-24\.04(\.\d+)?-live-server-amd64\.iso)') { $Matches['name'] }
} | Sort-Object {
    # sort by point release (null/empty -> 0)
    if ($_ -match '24\.04\.(\d+)') { [int]$Matches[1] } else { 0 }
  } -Descending | Select-Object -First 1)

if (-not $isoName) { Write-Error "Failed to parse ISO name from SHA256SUMS."; exit 1 }
$isoUrl  = "$ReleasesBase/$isoName"
$isoPath = Join-Path $Downloads $isoName

Write-Host "→ Latest ISO: $isoName" -ForegroundColor Cyan
Write-Host "→ Downloading to: $isoPath" -ForegroundColor Cyan

# --- download ISO (BITS if available, else Invoke-WebRequest)
try {
  Start-BitsTransfer -Source $isoUrl -Destination $isoPath -DisplayName "Ubuntu ISO ($isoName)" -ErrorAction Stop
} catch {
  Invoke-WebRequest $isoUrl -OutFile $isoPath -UseBasicParsing
}

# --- verify SHA256
$expected = (Select-String -Path $shaFile -Pattern [regex]::Escape($isoName)).Line.Split(' ')[0].Trim()
$actual   = (Get-FileHash $isoPath -Algorithm SHA256).Hash.ToLower()
if ($expected -ne $actual) {
  Write-Error "SHA256 mismatch! expected=$expected actual=$actual"
  exit 1
}
Write-Host "✓ Checksum OK" -ForegroundColor Green

# --- locate create-vm.ps1 and launch
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$creator  = Join-Path $repoRoot "hyperv\create-vm.ps1"
if (-not (Test-Path $creator)) { Write-Error "Missing $creator"; exit 1 }

& $creator -VMName $VMName -ISO $isoPath
