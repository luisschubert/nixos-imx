{
  description = "i.MX (8) specific Linux kernel, u-boot bootloader, firmware, etc packaged in Nix for NixOS";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/6da4bc6cb07cba1b8e53d139cbf1d2fb8061d967"; };
    functions = { url = "github:NiklasGollenstede/nix-functions/d4249dd208e055bfdf43a249894dabcac7ea8b24"; inputs.nixpkgs.follows = "nixpkgs"; };
    installer = {
      url = "github:NiklasGollenstede/nixos-installer/6a886a839df96ea37b3b256d5ea2fbbe549d68a8";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.functions.follows = "functions";
    };
    wiplib = {
      url = "github:NiklasGollenstede/nix-wiplib/b0587d12a6f9dab63c2023fd8ced3560a9e89d6a";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.functions.follows = "functions";
      inputs.installer.follows = "installer";
    };
  };

  outputs = inputs@{ self, ... }: inputs.functions.lib.importRepo (inputs // {
    # Inject config directly into inputs for nixos-installer and nix-wiplib
    config = {
      prefix = "wip"; # For nix-wiplib
      rename = {
        installer = "installer"; # For nixos-installer
        preface = "preface"; # For nixos-installer
      };
    };
  }) ./. (repo@{ overlays, ... }: let
    lib = inputs.nixpkgs.lib // { fun = inputs.functions.lib; inst = inputs.installer.lib; wip = inputs.wiplib.lib; };
  in [
    repo { lib.__internal__ = lib; }
    (lib.inst.mkSystemsFlake { inherit inputs; config = {
      prefix = "wip";
      rename = {
        installer = "installer";
        preface = "preface";
      };
    }; })
    (lib.inst.mkSystemsFlake { inherit inputs; config = {
      prefix = "wip";
      rename = {
        installer = "installer";
        preface = "preface";
      };
    }; buildPlatform = "x86_64-linux"; renameOutputs = key: "x64:${key}"; })
    (lib.fun.forEachSystem [ "aarch64-linux" "x86_64-linux" ] (localSystem: {
      packages = lib.fun.getModifiedPackages (lib.fun.importPkgs inputs { system = localSystem; }) overlays;
      defaultPackage = self.packages.${localSystem}.all-systems;
    }))
  ]);
}