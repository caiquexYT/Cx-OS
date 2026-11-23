# Cx OS

Cx OS is a lightweight, secure Linux distribution based on **Arch Linux** with the **Hyprland** compositor
and the **Cx OS shell** (a modified fork of [Caelestia](https://github.com/caelestia-dots/shell), see `NOTICE`).

## Highlights

- **Windows 11-style desktop**: bottom taskbar with Start/search, pinned and running apps (click to focus,
  click again to minimise), system tray, network/sound/battery, clock and "show desktop". Familiar shortcuts
  (`Alt+F4`, `Super+E`, `Super+L`, `Ctrl+Shift+Esc`, `Print`, `F11`).
- **Stays light over time**: apps run in their own systemd scopes (not inside the shell), stale launcher entries
  are released, notification history is capped, journal/coredumps are limited, zram + systemd-oomd.
- **Light mode for any PC**: blur, shadows and animations turn off automatically without a real GPU or with
  less than 4 GiB RAM (`CXOS_LIGHT_MODE=0|1` to force).
- **Cleanup**: `cxos-clean` (safe cache/trash/log/package cleanup; `--dry` to preview) plus weekly timers.
  `cxos-update` updates packages, Flatpak apps and firmware.
- **Security**: nftables firewall dropping all unsolicited inbound traffic, AppArmor, Firejail, kernel sysctl
  hardening, risky kernel modules blocked, no SSH server, core dumps disabled, root account locked.
- **Apps**: Flatpak (Flathub) and Wine/Winetricks for Windows programs.

## Layout

| Path | Contents |
|---|---|
| `shell/` | Cx OS shell (Quickshell/QML + C++ plugin) |
| `cli/` | `cxos` control utility (Python) |
| `dots/` | Hyprland, fish, foot and app configs |
| `packages/` | PKGBUILDs for `cxos-shell` and `cxos-cli` |
| `iso/` | archiso profile |

## Build

On Arch Linux (or an Arch container) with `archiso` and `base-devel`, add a `[cxos]` repo pointing to
`$REPO` in `/etc/pacman.conf`, then:

```sh
WORK=/work ./build.sh          # packages + ISO -> /work/out/cxos-*.iso
```

Test: `qemu-system-x86_64 -enable-kvm -m 4G -vga virtio -display gtk,gl=on -cdrom /work/out/cxos-*.iso`

In the live session run `cxos-install` to install to disk.

## License

GPL-3.0. Shell, CLI and dotfiles are derived from the Caelestia project by its contributors.
