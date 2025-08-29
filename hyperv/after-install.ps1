param([string]$VMName = "lab")
Stop-VM -Name $VMName -TurnOff -Force -ErrorAction SilentlyContinue
Set-VMDvdDrive -VMName $VMName -Path $null
Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMHardDiskDrive -VMName $VMName)
Start-VM -Name $VMName
