# UCLA Cybersecurity Lab Environment (Public)
See windows-hyperv-setup.md and macos-utm-setup.md.


## Quick start — Windows + Hyper-V (fast path)

```powershell
# 1) Download Ubuntu Server + checksum
$d="$env:USERPROFILE\Downloads"
iwr https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso -OutFile "$d\ubuntu-24.04.3-live-server-amd64.iso"
iwr https://releases.ubuntu.com/24.04.3/SHA256SUMS -OutFile "$d\SHA256SUMS"
$calc=(Get-FileHash "$d\ubuntu-24.04.3-live-server-amd64.iso" -Algorithm SHA256).Hash
$exp =(Select-String 'ubuntu-24.04.3-live-server-amd64.iso' "$d\SHA256SUMS").Line.Split(' ')[0]
if($calc -ne $exp){ throw "SHA256 mismatch" }

# 2) Create + boot VM (defaults: 4 vCPU, 8GB RAM, 80GB disk, NAT+HostOnly)
cd "$env:USERPROFILE\Documents\vm-lab-starter\hyperv"
.\create-vm.ps1 -VMName lab -ISO "$d\ubuntu-24.04.3-live-server-amd64.iso"

# 3) Install Ubuntu (Minimal + OpenSSH), then make disk first + eject ISO
.\after-install.ps1 -VMName lab

# 4) Set HostOnly IP inside VM (example: 192.168.200.24)
# /etc/netplan/60-hostonly.yaml
# network:
#   version: 2
#   ethernets:
#     eth1:
#       addresses: [192.168.200.24/24]
#       dhcp4: no
# sudo netplan apply

# 5) SSH in (from Windows) and harden to key-only
ssh student@192.168.200.24
curl -fsSL https://raw.githubusercontent.com/BrianMWright/vm-lab-starter/main/ubuntu/harden-ssh.sh | sudo bash

