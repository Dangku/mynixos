{ config, pkgs, lib, ... }:

{
  # imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  
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
      timeout = 3;
    };

    # !!! Otherwise (even if you have a Raspberry Pi 2 or 3), pick this:
    kernelPackages = pkgs.linuxPackages_latest;

    # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
    kernelParams = ["console=ttyS0,115200n8 cma=32M"];
  };

  # Enable serial communication ttyS0
  systemd.services."serial-getty@ttyS0".enable = false;
    
  # File systems configuration for using the installer's partition layout
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
    
  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  # Preinstall packages
  environment.systemPackages = with pkgs; [
    wget vim htop screen git usbutils python3 gcc gnumake tmux usb-modeswitch
  ];

  services = {

    # SSH
    openssh.enable = true;
    # openssh.permitRootLogin = "yes";

    # Xserver
    xserver = {
      enable = true;
      #videoDrivers = [ "fbturbo" ];

      # Enable touchpad support.
      libinput.enable = true;

      # Keyboard settings
      layout = "us";
      xkbVariant = "colemak";

      # display manager
      desktopManager.xfce.enable = true;
      displayManager.lightdm.enable = true;

      # X start at boot
      # The X server can be started manaually by command:
      # systemctl start display-manager.service
      autorun = false;
    };
  };

  # Define a user account. Don't forget to set a password with passwd.
  users.users.pi = {
      isNormalUser = true;
      home = "/home/pi";
      description = "bananapi";
      extraGroups = [ "wheel" "networkmanager" ];
      uid = 1000;

      openssh.authorizedKeys.keys = [ 
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC65z1oERS2K6iTqLWiKyOi2Zgz6N/A84M6sGbRAz+qYh8VlHH94K/sB+oeMrPL1kSZNx4aBC7Yt9XzVSQxOxCfuEHWxkIGGpY5+qggvMeKyulOPIoGr1KqGjdmodfpQptKeBnbkQB4FA6fpl5v4rBircOWnrEIDUY8t6ZwaMQE/KM9vQcsQuKuFdQYeD9faXNA0Nw5BBHn22nAisFttagyI9ergI8WSVsosGY9CJY394rzCpzfQGP1Tf9ATyPCH383pguGwNOpmMsQUwiqXSyNVMWESEAZP+KBodn6ejzfXqtTWQVf9uS4yOJpps5gcuMZXMq1IotNRYQqr6sREfpp dangku@dangku-desktop"
      ];
  };
}
