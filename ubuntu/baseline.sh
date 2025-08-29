#!/usr/bin/env bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install git tmux htop ufw
sudo ufw allow OpenSSH && sudo ufw --force enable


