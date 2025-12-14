#!/bin/bash

# Performs arch linux installation
# INFO: https://wiki.archlinux.org/title/Installation_guide

# You can either run this script or and commands invividually. The arch installation
# image usually comes with tmux and vim.

MY_DEVICE=${MY_DEVICE:-/dev/sda}
MY_SWAP_SIZE_MIB=${MY_SWAP_SIZE_MIB:-8192}
MY_HOSTNAME=${MY_HOSTNAME:-myarch}
MY_USERNAME=${MY_USERNAME:-vncsmyrnk}

to_lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

set -e

echo -e "-- Current setup --"
echo -e "DEVICE.......: $MY_DEVICE"
echo -e "SWAP_SIZE_MIB: $MY_SWAP_SIZE_MIB"
echo -e "HOSTNAME.....: $MY_HOSTNAME"
echo -e "USERNAME.....: $MY_USERNAME"
echo -e "PASSWORD.....: $MY_PASSWORD"
echo -e "ROOT_PASSWORD: $MY_ROOT_PASSWORD\n"

if [ -z "$MY_PASSWORD" ] || [ -z "$MY_ROOT_PASSWORD" ]; then
  echo "Please specify a user and root password via \$MY_PASSWORD and \$MY_ROOT_PASSWORD variables, respectively."
  exit 1
fi

read -p "This script will wipe the device and install arch. Continue? (y/N): " choice
if [[ "$(to_lower "$choice")" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

# Use timedatectl(1) to ensure the system clock is synchronized
timedatectl

# Sets keyboard layout; `localectl list-keymaps` to see more
echo "Setting keyboard layout..."
loadkeys br-abnt

# Disk partition
# INFO: https://wiki.archlinux.org/title/EFI_system_partition
# To list disks: `lsblk`; `fdisk -l`
# To Check partitions: `parted "$MY_DEVICE" print`
# To erase existing partitions: use fdisk to remove each one
echo "Partitioning disk..."

# Creates GPT partition table
parted "$MY_DEVICE" --script mklabel gpt

# sda1 /boot EFI
parted "$MY_DEVICE" --script mkpart EFI fat32 1MiB 1025MiB
parted "$MY_DEVICE" --script set 1 boot on

# sda2 swap
parted "$MY_DEVICE" --script mkpart swap linux-swap 1025MiB $(($MY_SWAP_SIZE_MIB+1025))MiB

# sda3 /
parted "$MY_DEVICE" --script mkpart root ext4 $(($MY_SWAP_SIZE_MIB+1025))MiB 100%

# Formats the EFI System Partition
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
# You can also edit /etc/pacman.d/mirrorlist manually and select just
# the ones near you
cat <<EOF > /etc/pacman.d/mirrorlist
Server = http://arch.mirror.constant.com/\$repo/os/\$arch
Server = https://archlinux.thaller.ws/\$repo/os/\$arch
Server = https://mirror.moson.org/arch/\$repo/os/\$arch
Server = http://archlinux.thaller.ws/\$repo/os/\$arch
Server = http://mirror.moson.org/arch/\$repo/os/\$arch
EOF

# Installs essential stuff
pacstrap -K /mnt base linux linux-firmware

# Configurations
echo "Applying general config..."

# Saves disks mouting points
genfstab -U /mnt >> /mnt/etc/fstab

# "Change root into the new system"
# Runs all of the following in it
arch-chroot /mnt /bin/bash <<EOFF
set -e

# Sets the timezone and clock
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Uses en_US.UTF-8
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
cat <<EOF > /etc/locale.conf
LANG=en_US.UTF-8
EOF

# Keyboard layout
cat <<EOF > /etc/vconsole.conf
KEYMAP=br-abnt
EOF

# Sets hostname
cat <<EOF > /etc/hostname
$MY_HOSTNAME
EOF

# Recreates the initramfs image
mkinitcpio -P

# Sets root password. Can be set with `passwd`
echo "root:$MY_ROOT_PASSWORD" | chpasswd

# Boot loader
# INFO: https://wiki.archlinux.org/title/GRUB
echo "Setting up GRUB..."

# Installs GRUB
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Generates the main configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Creates the user and adds it to the wheel group
# To set it manually: `passwd "$USERNAME"`
useradd -m -G wheel -s /bin/bash $MY_USERNAME

# Sets the users password
echo "$MY_USERNAME:$MY_PASSWORD" | chpasswd

# Installs additional packages
pacman -Syu --noconfirm gnome gdm
pacman -Syu --noconfirm base base-devel sudo networkmanager \
  kitty git neovim just \
  docker docker-buildx intel-ucode \
  fastfetch net-tools

# For drivers
# https://wiki.archlinux.org/title/NVIDIA (usually `nvidia-open`)
# https://wiki.archlinux.org/title/AMDGPU (usually `xf86-video-amdgpu`)

# Enables sudo for the wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Installs yay
sudo -u $MY_USERNAME /bin/bash <<EOF
cd /home/$MY_USERNAME
git clone https://aur.archlinux.org/yay-bin.git
(cd yay-bin && makepkg -si --noconfirm)
EOF

# Enables services
systemctl enable systemd-networkd NetworkManager gdm

# Generates locale
locale-gen en_US.UTF-8
EOFF

# Final steps
echo "All Done. Everything OK"
read -p "Unmount and reboot? (Y/n): " reboot
if [[ "$(to_lower "$reboot")" -= "n" ]]; then
  exit 0
fi

# Unmount everything
umount -R /mnt

# Reboots
reboot
