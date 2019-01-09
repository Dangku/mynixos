### NixOS


----------


#### **Prepare**
 
Download base image according to your board ISA:
```sh
$ wget https://www.cs.helsinki.fi/u/tmtynkky/nixos-arm/installer/sd-image-aarch64-linux.img

$ wget https://www.cs.helsinki.fi/u/tmtynkky/nixos-arm/installer/sd-image-armv7l-linux.img

$ wget https://www.cs.helsinki.fi/u/tmtynkky/nixos-arm/installer/sd-image-armv6l-linux.img
```

Flash the base image to SD card

    $ sudo dd if=sd-image-xxx-linux.img bs=1M of=/dev/sdX conv=fsync


----------


####**Board specific Installation & Configuration**

BPI boards

Download the mainline uboot and build for target board, pay attention to the difference between arm32 and aarch64 uboot compile. After build successfully, flash the u-boot binary to the sd card.

    $ sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/sdX bs=1024 seek=8

Raspberry 3

Set the **console=ttyS0,115200n8** in /NIXOS_BOOT/extlinux/extlinux.conf, otherwise you might hang on the line "Starting kernel ...". if you try to use UART to log on NixOS

Turn on target board, default auto login as root, then set password and start sshd:

```sh
# passwd

# systemctl start sshd
```


----------


#### **Build NixOS**

Connect to target board with ssh:

```sh
$ ssh root@<ip-address>
```
Download and run script:
```sh

# curl --insecure https://raw.githubusercontent.com/Dangku/mynixos/master/nixos_build.sh --output nixos_build.sh -L

# chmod +x nixos_build.sh

# ./nixos_build.sh
```


----------
Thanks to https://github.com/tuuzdu/de_aira_rpi (Ivan Biriuk)
