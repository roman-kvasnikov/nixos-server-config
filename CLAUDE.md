# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS home server configuration repository designed for a headless NAS and media server setup. The configuration is managed using Nix flakes and provides services like Jellyfin (media server), Immich (photo management), and Samba (file sharing).

## Architecture

The repository follows a modular NixOS configuration structure:

- `flake.nix` - Main entry point defining the system configuration for hostname "home-server"
- `hosts/home-server/` - Host-specific configuration files
  - `configuration.nix` - Main host configuration importing hardware config and nixos modules
  - `hardware-configuration.nix` - Hardware-specific settings
- `nixos/` - Reusable NixOS modules and packages
  - `default.nix` - Imports all modules and packages
  - `packages.nix` - System-wide package definitions (CLI tools, archives, monitoring)
  - `modules/` - Individual service and system configuration modules

### Key Service Modules

- `immich.nix` - Photo management service (port 2283)
- `jellyfin.nix` - Media server (port 8096)
- `samba.nix` - File sharing service
- `xrdp.nix` - Remote desktop access
- `cockpit.nix` - Web-based system administration
- `networking.nix` - Network configuration
- `user.nix` - User account management

## Common Commands

### System Management
```bash
# Build and switch to new configuration
sudo nixos-rebuild switch --flake .#home-server

# Build configuration without switching
sudo nixos-rebuild build --flake .#home-server

# Test configuration (temporary activation)
sudo nixos-rebuild test --flake .#home-server

# Check flake syntax and inputs
nix flake check

# Update flake inputs
nix flake update
```

### Development Workflow
```bash
# Quick commit and push (uses timestamp as commit message)
./git-push.sh

# Manual git workflow
git add .
git commit -m "your message"
git push
```

### Service Management
```bash
# Check service status
systemctl status jellyfin
systemctl status immich-server
systemctl status smbd

# View service logs
journalctl -u jellyfin -f
journalctl -u immich-server -f
```

## Service Ports

- Jellyfin: 8096 (media server web UI)
- Immich: 2283 (photo management web UI)
- SSH: 22 (remote access)
- XRDP: 3389 (remote desktop, if enabled)

## Development Notes

- The system is configured for headless operation with remote administration
- All services have firewall ports automatically opened in their respective modules
- The configuration allows unfree packages (nixpkgs.config.allowUnfree = true)
- System packages include essential CLI tools, file managers (eza, tree), and monitoring tools (htop, btop)