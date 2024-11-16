#!/bin/bash

# Performs arch linux installation
# Reference: https://wiki.archlinux.org/title/Installation_guide

MY_DEVICE=/dev/sda
MY_SWAP_SIZE_MIB=8192
MY_HOSTNAME=myarch
MY_USERNAME=vncsmyrnk

echo -e "-- Current setup --"
echo -e "DEVICE.......: $MY_DEVICE"
echo -e "SWAP_SIZE_MIB: $MY_SWAP_SIZE_MIB"
echo -e "HOSTNAME.....: $MY_HOSTNAME"
echo -e "USERNAME.....: $MY_USERNAME"
echo -e "PASSWORD.....: $MY_PASSWORD\n"

if [ -z "$MY_PASSWORD" ]; then
  echo "Please specify a password via \$MY_PASSWORD variable"
  exit 1
fi

read -p "This script will wipe the device and install arch. Continue? (y/N): " choice
choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
if [[ "$choice" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

# Sets keyboard layout; `localectl list-keymaps` to see more
echo "Setting keyboard layout..."
loadkeys br-abnt

# Disk partition
# Reference: https://wiki.archlinux.org/title/EFI_system_partition
echo "Partitioning disk..."

# Creates GPT partition table
parted "$MY_DEVICE" --script mklabel gpt

# sda1 /boot EFI
parted "$MY_DEVICE" --script mkpart ESP fat32 1MiB 513MiB
parted "$MY_DEVICE" --script set 1 boot on

# sda2 swap
parted "$MY_DEVICE" --script mkpart primary linux-swap 513MiB $(($MY_SWAP_SIZE_MIB+513))MiB

# sda3 /
parted "$MY_DEVICE" --script mkpart primary ext4 4609MiB 100%

# Formats the EFI System Partition (ESP)
mkfs.fat -F32 "$MY_DEVICE"1

# Formats the root (/) partition
mkfs.ext4 "$MY_DEVICE"3

# Formats the swap partition
mkswap "$MY_DEVICE"2

# Enables the swap partition
swapon "$MY_DEVICE"2

# Mounts the root partition
mount "$MY_DEVICE"3 /mnt

# Mounts the EFI partition
mount --mkdir "$MY_DEVICE"1 /mnt/boot

# Install essential packages
echo "Installing essential packages..."

# Uses the closest mirrors; can later be updated with `reflector`
cat <<EOF > /etc/pacman.d/mirrorlist
Server = http://arch.mirror.constant.com/$repo/os/$arch
Server = https://archlinux.thaller.ws/$repo/os/$arch
Server = https://mirror.moson.org/arch/$repo/os/$arch
Server = http://archlinux.thaller.ws/$repo/os/$arch
Server = http://mirror.moson.org/arch/$repo/os/$arch
EOF

# Installs essential stuff
pacstrap -K /mnt base linux linux-firmware

# Configurations
echo "Applying general config..."

# Saves disks mouting points
genfstab -U /mnt >> /mnt/etc/fstab

# "Change root into the new system"
arch-chroot /mnt

# Sets the timezone and clock
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Localization

# Uses en_US.UTF-8
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
cat <<EOF > /etc/locale.conf
LANG=en_US.UTF-8
EOF

# Keyboard layout
cat <<EOF > /etc/vconsole.conf
KEYMAP=br-abnt
EOF

# Network

# Sets hostname
cat <<EOF > /etc/hostname
$MY_HOSTNAME
EOF

# Other

# Recreates the initramfs image
mkinitcpio -P

# Sets root password
passwd

# Boot loader
# Rerefence: https://wiki.archlinux.org/title/GRUB
echo "Setting up GRUB..."

# Installs GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# Generates the main configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# User

# Creates user
useradd -m -G wheel $USERNAME

# Enables sudo for the wheel group
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Install additional packages

pacman -S base base-devel \
  kitty yay git \
  docker docker-buildx \
  neovim just google-chrome

# Final steps
echo "Everything OK. Rebooting..."

# Unmount everything
umount -R /mnt

# Reboots
reboot
