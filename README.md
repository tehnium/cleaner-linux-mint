# Ubuntu Cleanup Script

A simple Bash script for Ubuntu/Debian-based systems that performs system cleanup and safely removes old kernels.

## What it does

This script helps reduce disk usage and keep the system clean by:

- Running APT cleanup commands:
  - `autoremove --purge`
  - `autoclean`
  - `clean`
- Removing cached APT list files
- Detecting the currently running kernel
- Keeping:
  - the current kernel
  - one fallback kernel
- Purging older unused kernel packages:
  - `linux-image`
  - `linux-headers`
  - `linux-modules`
  - `linux-modules-extra`
  - related tools packages, if installed
- Removing orphaned `initrd.img-*` files
- Rebuilding initramfs only for the current kernel
- Updating GRUB
- Purging leftover `rc` packages

## Why use it

Over time, Ubuntu may keep several old kernel versions installed. This script automates cleanup in a safer way by keeping the active kernel and one backup kernel instead of trying to remove everything blindly.

## Requirements

- Ubuntu or Debian-based Linux distribution
- `bash`
- `apt-get`
- `dpkg-query`
- `update-initramfs`
- `update-grub`
- Root privileges

## Usage

### 1. Save the script

Save the script as:

```bash
cleanup.sh
```

### 2. Make it executable

```bash
chmod +x cleanup.sh
```

### 3. Run it as root

```bash
sudo ./cleanup.sh
```

## Example

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
chmod +x cleanup.sh
sudo ./cleanup.sh
```

## Safety notes

- The script is intended for Ubuntu/Debian-based systems.
- It keeps the currently running kernel.
- It also keeps one fallback kernel for recovery.
- Review the script before using it on production systems.
- Do not run it if you are not sure how your boot setup is managed.

## Recommended checks after running

You can verify installed kernels with:

```bash
dpkg -l 'linux-image-*' | awk '/^ii/{print $2}'
```

You can verify remaining initramfs images with:

```bash
ls -lh /boot/initrd.img-*
```

## What it does not do

- It does not remove the currently running kernel.
- It does not remove all kernels blindly.
- It does not depend on external third-party tools.

## License

MIT License

## Disclaimer

Use this script at your own risk. Always test on a non-critical machine first and make sure you have a working backup or recovery option.
