#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Ruleaza scriptul cu sudo:"
  echo "  sudo $0"
  exit 1
fi

echo "==> Cleaning apt cache"
apt-get -y autoremove --purge
apt-get -y autoclean
apt-get -y clean
rm -rf /var/lib/apt/lists/*
mkdir -p /var/lib/apt/lists/partial

echo "==> Detecting installed kernels"
current_kernel="$(uname -r)"

mapfile -t installed_kernels < <(
  dpkg-query -W -f='${Package}\n' 'linux-image-[0-9]*' 'linux-image-unsigned-[0-9]*' 2>/dev/null \
    | sed -E 's/^linux-image(-unsigned)?-//' \
    | sort -Vu
)

echo "Current kernel: $current_kernel"

keep_fallback=""
for ver in "${installed_kernels[@]}"; do
  if [[ "$ver" != "$current_kernel" ]]; then
    keep_fallback="$ver"
  fi
done

if [[ -n "$keep_fallback" ]]; then
  echo "Backup kernel kept: $keep_fallback"
else
  echo "No backup kernel found. Only current kernel will be kept."
fi

purge_kernel_version() {
  local ver="$1"
  local base="${ver%-*}"
  local candidates=(
    "linux-image-$ver"
    "linux-image-unsigned-$ver"
    "linux-headers-$ver"
    "linux-headers-$base"
    "linux-modules-$ver"
    "linux-modules-extra-$ver"
    "linux-tools-$ver"
    "linux-cloud-tools-$ver"
  )
  local to_purge=()
  local pkg

  for pkg in "${candidates[@]}"; do
    if dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -q '^install ok installed$'; then
      to_purge+=("$pkg")
    fi
  done

  if ((${#to_purge[@]})); then
    echo "Purging: ${to_purge[*]}"
    apt-get -y purge "${to_purge[@]}"
  fi
}

echo "==> Removing old kernels"
for ver in "${installed_kernels[@]}"; do
  [[ "$ver" == "$current_kernel" ]] && continue
  [[ -n "$keep_fallback" && "$ver" == "$keep_fallback" ]] && continue
  purge_kernel_version "$ver"
done

echo "==> Autoremove after kernel purge"
apt-get -y autoremove --purge

echo "==> Removing orphan initrd images"
shopt -s nullglob
for img in /boot/initrd.img-*; do
  ver="${img#/boot/initrd.img-}"

  if dpkg-query -W -f='${Status}\n' "linux-image-$ver" 2>/dev/null | grep -q '^install ok installed$'; then
    continue
  fi

  if dpkg-query -W -f='${Status}\n' "linux-image-unsigned-$ver" 2>/dev/null | grep -q '^install ok installed$'; then
    continue
  fi

  echo "Removing orphan initrd: $img"
  update-initramfs -d -k "$ver" 2>/dev/null || rm -f "$img"
done
shopt -u nullglob

echo "==> Updating current initramfs only"
update-initramfs -u -k "$current_kernel"

echo "==> Updating grub"
if command -v update-grub >/dev/null 2>&1; then
  update-grub
fi

echo "==> Removing leftover rc packages"
mapfile -t rc_pkgs < <(dpkg -l | awk '/^rc/{print $2}')
if ((${#rc_pkgs[@]})); then
  dpkg --purge "${rc_pkgs[@]}"
fi

echo "==> Done"
echo "Kept kernels: $current_kernel${keep_fallback:+ and $keep_fallback}"
