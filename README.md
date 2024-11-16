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
