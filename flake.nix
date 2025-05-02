{
  description = (
    "i.MX (8) specific Linux kernel, u-boot bootloader, firmware, etc packaged in Nix for NixOS"
  );

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/6da4bc6cb07cba1b8e53d139cbf1d2fb8061d967"; };
    functions = { url = "github:NiklasGollenstede/nix-functions/"; inputs.nixpkgs.follows = "nixpkgs"; };
    installer = { url = "github:NiklasGollenstede/nixos-installer"; inputs.nixpkgs.follows = "nixpkgs"; inputs.functions.follows = "functions"; };
    wiplib = { url = "github:NiklasGollenstede/nix-wiplib/"; inputs.nixpkgs.follows = "nixpkgs"; inputs.functions.follows = "functions"; inputs.installer.follows = "installer"; };
    # nixos-imx = { url = "github:luisschubert/nixos-imx/f9704c92c66d55c1d66989fae47a42a66bf52b2c"; inputs.nixpkgs.follows = "nixpkgs"; inputs.wiplib.follows = "wiplib"; };
    config = { url = "path:./example/defaultConfig"; };
  };

  outputs = inputs@{ self, ... }: inputs.functions.lib.importRepo inputs ./. (repo@{ overlays, ... }: let
    lib = inputs.nixpkgs.lib // { fun = inputs.functions.lib; inst = inputs.installer.lib; wip = inputs.wiplib.lib; };
  in [
    repo { lib.__internal__ = lib; }
    (lib.inst.mkSystemsFlake { inherit inputs; })
    (lib.inst.mkSystemsFlake { inherit inputs; buildPlatform = "x86_64-linux"; renameOutputs = key: "x64:${key}"; })
    (lib.fun.forEachSystem [ "aarch64-linux" "x86_64-linux" ] (localSystem: {
      packages = lib.fun.getModifiedPackages (lib.fun.importPkgs inputs { system = localSystem; }) overlays;
      defaultPackage = self.packages.${localSystem}.all-systems;
    }))
  ]);
}
