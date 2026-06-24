{
  description = "My Home Manager Flake Config";

  inputs = {
    # 安定版のnixpkgsを使用（2026年現在の最新安定版例）
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    
    # Home Managerの入力をnixpkgsと同期
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux"; # M1/M2/M3 Macの場合は "aarch64-darwin"
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."kwatanabe-nix" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # home.nixを読み込む
        modules = [ ./home.nix ];
      };
    };
}
