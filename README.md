# Arch

Useful information about arch config and utilities.

## Useful links

- [Wiki](https://wiki.archlinux.org/title/Main_page)
- [ISOs](https://archlinux.org/download/)

## Archinstall

```bash
curl -LO https://raw.githubusercontent.com/vncsmyrnk/arch/refs/heads/main/install.sh
chmod +x install.sh
MY_PASSWORD=password MY_ROOT_PASSWORD=root_password ./install.sh
```

## Encrypting partitions

[dm-crypt](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)
[GRUB Setup](https://bbs.archlinux.org/viewtopic.php?id=301301)
[Reencrypt a device](https://unix.stackexchange.com/questions/444931/is-there-a-way-to-encrypt-disk-without-formatting-it)
[GRUB regenerate the config file](https://wiki.archlinux.org/title/GRUB#Generate_the_main_configuration_file)

## Installation caveats

### Networking

Reference: https://wiki.archlinux.org/title/Network_configuration

```bash
cat <<EOF > /etc/systemd/network/20-wired.network
[Match]
Name=enp2s0

[Network]
DHCP=yes
EOF
```

```bash
cat "nameserver 8.8.8.8" > /etc/resolv.conf
sudo pacman -S networkmanager
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
```

```bash
ping 8.8.8.8 # for testing
```

### GPU Drivers

```bash
sudo pacman -S mesa xf86-video-amdgpu
```

### Using system clipboard in vim

Vim is useful during the installation for running the commands one by one. Using the system clipboard in this scenario is very useful.

- Install `vim-gtk3`
- Set the clipboard inside vim: `set clipboard=unnamedplus`

### Increase archiso disk space

When needing space for installing packages on the archiso:

```sh
mount -o remount,size=1G /run/archiso/cow
```
