{ config, pkgs, lib, ... }:

{
  # imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];

  hardware = {
    # usbWwan.enable = true;
    ### WiFi driver
    enableRedistributableFirmware = true;
    firmware = [
      (pkgs.stdenv.mkDerivation {
        name = "broadcom-rpi3-extra";
        src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/RPi-Distro/firmware-nonfree/54bab3d/brcm80211/brcm/brcmfmac43430-sdio.txt";
        sha256 = "19bmdd7w0xzybfassn7x4rb30l70vynnw3c80nlapna2k57xwbw7";
        };
        phases = [ "installPhase" ];
        installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        cp $src $out/lib/firmware/brcm/brcmfmac43430-sdio.txt
        '';
      })
    ];
  };

  # Select internationalisation properties
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  # Select timezone
  time.timeZone = "Europe/Moscow";

  boot = {
    loader = {
      # NixOS wants to enable GRUB by default
      grub.enable = false;
      # Enables the generation of /boot/extlinux/extlinux.conf
      generic-extlinux-compatible.enable = false;
      # Autoboot without serial port interrupt on extlinux
      timeout = -1;
      raspberryPi = {
        enable = true;
        uboot.enable = true;
        uboot.configurationLimit = 10;
        version = 3;
        # Autoboot without serial port interrupt on uboot
        firmwareConfig = ''
          boot_delay=-1
        '';
      };
    };
    # !!! Otherwise (even if you have a Raspberry Pi 2 or 3), pick this:
    kernelPackages = pkgs.linuxPackages_latest;
    # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
    # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
    kernelParams = ["console=ttyS1,115200n8 cma=256M"];
  };

  # Enable serial communication ttyS1
  systemd.services."serial-getty@ttyS1".enable = false;
    
  # File systems configuration for using the installer's partition layout
  fileSystems = {
    #"/boot" = {
    #  device = "/dev/disk/by-label/NIXOS_BOOT";
    #  fsType = "vfat";
    #};
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
    
  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  # WiFi AP, open ports, hosts for remote ROS onnections
  networking = {
    # Open ports for ROS
    firewall.enable = false;
    # Hosts for remote ROS connections
    hosts = { "192.168.0.106" = [ "tuuzdu-AIR13" ]; };
    # WiFi AP
    interfaces.wlan0.ipv4.addresses = [ { address = "172.16.1.1"; prefixLength = 24; } ];
    # Bridge for Internet connection via WiFi
    # bridges.br0.interfaces = [ "eth0" ];
    # wireless.enable = true;
    # wireless.interfaces = ["wlan1"];
    # wireless.networks = { 
    #   "fftlt.net" = {
    #    # psk = "";
    #   };
    # };
  };

  # Build AIRA packages
  nix.useSandbox = false;

  # Preinstall packages
  environment.systemPackages = with pkgs; [
    wget vim htop screen git usbutils python3 gcc gnumake tmux usb-modeswitch
  ];

  services = {

    # X
    xserver = {
      enable = true;
      videoDrivers = [ "fbturbo" ];
      # Enable touchpad support.
      libinput.enable = true;
      # Keyboard settings
      layout = "us";
      xkbVariant = "colemak";
      desktopManager.xfce.enable = true;
      displayManager.lightdm.enable = true;
      autorun = false;
    };

    # For Huawei E3372 ethernet mode
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb",
      ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="1f01",
      RUN+="${pkgs.usb-modeswitch.outPath}/bin/usb_modeswitch -v 0x12d1 -p 0x1f01 -V 0x12d1 -P 0x14dс -J"
    '';

    # WiFi AP
    hostapd = {
      enable = true;
      interface = "wlan0";
      wpa = true;
      ssid = "rpi";
      wpaPassphrase = "12345678";
      extraConfig = ''
        hw_mode=g
        channel=10
        auth_algs=1
        wpa_key_mgmt=WPA-PSK
        # wpa_pairwise=CCMP
        rsn_pairwise=CCMP
        ieee80211n=1
        wmm_enabled=0
        # bridge=br0
      '';
    };

    dhcpd4 = {
      enable = true;
      interfaces = [ "wlan0" ];
      extraConfig = ''
        ddns-update-style none;
        ignore client-updates;
        authoritative;
        option local-wpad code 252 = text;
        subnet
        10.0.0.0 netmask 255.255.255.0 {
          option routers 172.16.1.1;
          option subnet-mask 255.255.255.0;
          option broadcast-address 172.16.1.255;
          option domain-name-servers 8.8.8.8, 8.8.4.4;
          option time-offset 0;
          range 172.16.1.2 172.16.1.10;
          default-lease-time 1209600;
          max-lease-time 1814400;
        }
      '';
    };

    # IPFS
    ipfs = {
      enable = true;
      pubsubExperiment = true;
      extraConfig = {
        # Swarm.ConnMgr.HighWater = 5;
        # Swarm.ConnMgr.LowWater = 10;
        # Swarm.ConnMgr.GracePeriod = "20s";
        # Swarm.ConnMgr.Type = "basic";
        # Reprovider.Strategy = "pinned";
        # Swarm.DisableBandwidthMetrics = true;
        Bootstrap = [
          "/ip4/13.95.236.166/tcp/4001/ipfs/QmdfQmbmXt6sqjZyowxPUsmvBsgSGQjm4VXrV7WGy62dv8"
          "/ip6/fcd5:9d3a:b122:3de1:2742:a3b7:c9c4:46d9/tcp/4001/ipfs/QmdfQmbmXt6sqjZyowxPUsmvBsgSGQjm4VXrV7WGy62dv8"
          "/dns4/lighthouse.aira.life/tcp/4001/ipfs/QmdfQmbmXt6sqjZyowxPUsmvBsgSGQjm4VXrV7WGy62dv8"
          "/dns6/h.lighthouse.aira.life/tcp/4001/ipfs/QmdfQmbmXt6sqjZyowxPUsmvBsgSGQjm4VXrV7WGy62dv8"
          "/ip4/52.178.99.60/tcp/4001/ipfs/Qmc4eQzRttAug8vZ2aFqTsUqzUVymvUJZFBiQHL36Vvfri"
          "/ip6/fca9:fe44:52fd:5bd4:aa41:44de:750d:bad0/tcp/4001/ipfs/Qmc4eQzRttAug8vZ2aFqTsUqzUVymvUJZFBiQHL36Vvfri"
        ];
      };
    };

    # CJDNS
    cjdns = {
      enable = true;
      authorizedPasswords = [ "aira-cjdns-node" ];
      ETHInterface = {
        bind = "all";
        beacon = 2;
      };
      UDPInterface = {
        bind = "0.0.0.0:42000";
        connectTo = {
          # Akru/Strasbourg
          "164.132.111.49:53741" = {
            password = "cr36pn2tp8u91s672pw2uu61u54ryu8";
            publicKey = "35mdjzlxmsnuhc30ny4rhjyu5r1wdvhb09dctd1q5dcbq6r40qs0.k";
          };
          # Airalab/DigitalOcean
          "188.226.158.11:25829" = {
            password = ";@d.LP2589zUUA24837|PYFzq1X89O";
            publicKey = "kpu6yf1xsgbfh2lgd7fjv2dlvxx4vk56mmuz30gsmur83b24k9g0.k";
          };
        };
      };
    };

    # parity = {
    #   enable = true;
    #   unlock = true;
    #   light = true;
    # };

    # SSH
    openssh.enable = true;
    # openssh.permitRootLogin = "yes";
  };

  users = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    extraUsers.de = {
      extraGroups = [ "dialout" "wheel" "networkmanager" ];
      isNormalUser = true;
      # useDefaultShell = true;
      uid = 1000;

      openssh.authorizedKeys.keys = [ 
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC65z1oERS2K6iTqLWiKyOi2Zgz6N/A84M6sGbRAz+qYh8VlHH94K/sB+oeMrPL1kSZNx4aBC7Yt9XzVSQxOxCfuEHWxkIGGpY5+qggvMeKyulOPIoGr1KqGjdmodfpQptKeBnbkQB4FA6fpl5v4rBircOWnrEIDUY8t6ZwaMQE/KM9vQcsQuKuFdQYeD9faXNA0Nw5BBHn22nAisFttagyI9ergI8WSVsosGY9CJY394rzCpzfQGP1Tf9ATyPCH383pguGwNOpmMsQUwiqXSyNVMWESEAZP+KBodn6ejzfXqtTWQVf9uS4yOJpps5gcuMZXMq1IotNRYQqr6sREfpp dangku@dangku-desktop"
      ];
    };
  };
}
