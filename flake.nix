{
  description = "My Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      username = "new_user";
      homeDirectory = "/home/${username}";

      pkgs = import nixpkgs {
        inherit system;

        # vscode, chrome, slack みたいな unfree パッケージを入れたくなった時用
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.${username} =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit username homeDirectory;
          };

          modules = [
            ./home.nix
          ];
        };
    };
}
