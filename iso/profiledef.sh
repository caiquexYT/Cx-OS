#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="cxos"
iso_label="CXOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Cx OS <https://github.com/caiquexYT/Cx-OS>"
iso_application="Cx OS Live/Install"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="cxos"
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86,arm64' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
kernel_params_aarch64="clk_ignore_unused pd_ignore_unused arm64.nopauth"
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/cxos-clean"]="0:0:755"
  ["/usr/local/bin/cxos-update"]="0:0:755"
  ["/usr/local/bin/cxos-install"]="0:0:755"
  ["/usr/local/bin/cxos-live-user"]="0:0:755"
  ["/usr/local/bin/cxos-postinstall"]="0:0:755"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/10-cxos"]="0:0:440"
  ["/etc/sudoers.d/90-cxos-live"]="0:0:440"
)
