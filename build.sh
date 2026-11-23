#!/usr/bin/env bash
# Build Cx OS: local packages + ISO. Requires an Arch Linux host (or container) with
# archiso, base-devel and a [cxos] repo entry in /etc/pacman.conf pointing to $REPO.
#   ./build.sh packages   build AUR deps + cxos-shell + cxos-cli into $REPO
#   ./build.sh iso        build the ISO into $OUT
#   ./build.sh            both
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-/work}
REPO=${REPO:-$WORK/repo}
OUT=${OUT:-$WORK/out}
AUR_DEPS=(qt6-m3shapes-git quickshell-git libcava ttf-rubik-vf python-materialyoucolor)

build_pkg() { # dir
    (cd "$1" && PKGDEST=$REPO makepkg -sf --noconfirm --needed --skippgpcheck)
    (cd "$REPO" && repo-add -q -R cxos.db.tar.gz ./*.pkg.tar.zst)
    sudo pacman -Sy --noconfirm >/dev/null
}

packages() {
    mkdir -p "$REPO" "$WORK/aur"
    [[ -f $REPO/cxos.db.tar.gz ]] || repo-add -q "$REPO/cxos.db.tar.gz"
    for p in "${AUR_DEPS[@]}"; do
        [[ -d $WORK/aur/$p ]] || git clone -q "https://aur.archlinux.org/$p.git" "$WORK/aur/$p"
        build_pkg "$WORK/aur/$p"
    done
    build_pkg "$ROOT/packages/cxos-cli"
    build_pkg "$ROOT/packages/cxos-shell"
}

iso() {
    local prof=$WORK/profile
    rm -rf "$prof" && cp -a "$ROOT/iso" "$prof"
    sed -i "s|file:///work/repo|file://$REPO|" "$prof/pacman.conf"
    mkdir -p "$prof/airootfs/opt/cxos-repo"
    cp "$REPO"/cxos.db* "$REPO"/cxos.files* "$prof/airootfs/opt/cxos-repo/"
    find "$REPO" -maxdepth 1 -name '*.pkg.tar.zst' ! -name '*-debug-*' -exec cp {} "$prof/airootfs/opt/cxos-repo/" \;
    sudo mkarchiso -v -w "$WORK/iso-work" -o "$OUT" "$prof"
    sudo rm -rf "$WORK/iso-work"
}

case ${1:-all} in
    packages) packages ;;
    iso) iso ;;
    all) packages; iso ;;
    *) sed -n '2,7p' "$0"; exit 1 ;;
esac
