<# Generic Hyper-V VM creator (public)
   - Gen2 VM, Secure Boot (Linux template by default)
   - NAT ("Default Switch") + HostOnly (192.168.200.1/24)
   Usage:
     .\create-vm.ps1 -VMName lab -ISO "$env:USERPROFILE\Downloads\ubuntu-24.04.3-live-server-amd64.iso"
#>
param(
  [Parameter(Mandatory=$true)][string]$VMName,
  [Parameter(Mandatory=$true)][string]$ISO,
  [string]$VMRoot = "$env:USERPROFILE\Documents\VMs",
  [int]$CPUs = 4,
  [int]$MemoryGB = 8,
  [int]$DiskGB = 80,
  [string]$NatSwitch = "Default Switch",
  [string]$HostOnlySwitch = "HostOnly",
  [string]$HostOnlyHostIP = "192.168.200.1",
  [string]$SecureBootTemplate = "MicrosoftUEFICertificateAuthority"  # Use "MicrosoftWindows" for Windows ISOs
)
$VhdPath = Join-Path (Join-Path $VMRoot $VMName) "$VMName.vhdx"
New-Item -ItemType Directory -Path (Split-Path $VhdPath) -Force | Out-Null

# Ensure HostOnly switch + host IP
if (-not (Get-VMSwitch -Name $HostOnlySwitch -ErrorAction SilentlyContinue)) {
  New-VMSwitch -Name $HostOnlySwitch -SwitchType Internal | Out-Null
}
$hostIf = "vEthernet ($HostOnlySwitch)"
if (-not (Get-NetIPAddress -InterfaceAlias $hostIf -AddressFamily IPv4 -ErrorAction SilentlyContinue)) {
  New-NetIPAddress -InterfaceAlias $hostIf -IPAddress $HostOnlyHostIP -PrefixLength 24 | Out-Null
}

# Create VM if needed
if (-not (Get-VM -Name $VMName -ErrorAction SilentlyContinue)) {
  New-VM -Name $VMName -Generation 2 -MemoryStartupBytes ($MemoryGB*1GB) `
    -NewVHDPath $VhdPath -NewVHDSizeBytes ($DiskGB*1GB) -SwitchName $NatSwitch | Out-Null
  Set-VMProcessor -VMName $VMName -Count $CPUs
  Set-VMMemory    -VMName $VMName -DynamicMemoryEnabled $false
  Set-VMFirmware  -VMName $VMName -EnableSecureBoot On -SecureBootTemplate $SecureBootTemplate
  Add-VMNetworkAdapter -VMName $VMName -SwitchName $HostOnlySwitch -Name "HostOnly" | Out-Null
}

# Attach ISO and boot from DVD first
if (-not (Get-VMDvdDrive -VMName $VMName -ErrorAction SilentlyContinue)) {
  Add-VMDvdDrive -VMName $VMName -Path $ISO | Out-Null
} else {
  Set-VMDvdDrive -VMName $VMName -Path $ISO | Out-Null
}
Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMDvdDrive -VMName $VMName)
Start-VM -Name $VMName | Out-Null

Write-Host "`n✅ VM '$VMName' started from ISO." -ForegroundColor Green
Write-Host "After install, run:" -ForegroundColor Cyan
Write-Host "  Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMHardDiskDrive -VMName $VMName)"
Write-Host "  Set-VMDvdDrive -VMName $VMName -Path `$null"
