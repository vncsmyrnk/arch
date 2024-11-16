# Arch

Useful information about arch config and utilities.

## Useful links

- [Wiki](https://wiki.archlinux.org/title/Main_page)
- [ISOs](https://archlinux.org/download/)

## Archinstall

```bash
sh <(curl -L https://raw.githubusercontent.com/vncsmyrnk/arch/refs/heads/main/install.sh)
```

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
