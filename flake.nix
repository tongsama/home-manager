{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;

      # Pure evaluation fallback.
      #
      # This keeps a no---impure path available.
      # If local.nix exists but --impure is forgotten, home.nix will stop
      # activation before modifying files.
      defaultConfig = {
        username = "new_user";
        homePrefix = "/home";
        system = "x86_64-linux";
      };

      localConfigPathString =
        let
          envPath = builtins.getEnv "HM_LOCAL_CONFIG";
          home = builtins.getEnv "HOME";
        in
          if envPath != "" then
            envPath
          else if home != "" then
            "${home}/.config/home-manager/local.nix"
          else
            "";

      localConfigPath =
        if localConfigPathString != "" then
          /. + localConfigPathString
        else
          null;

      localConfigLoaded =
        localConfigPath != null && builtins.pathExists localConfigPath;

      localConfig =
        if localConfigLoaded then
          import localConfigPath
        else
          {};

      effectiveConfig = defaultConfig // localConfig;

      # 追加パッケージ群(optionalモジュール)の構成。
      # local.nix の `modules` で上書きできる (例: modules = { oci = false; };)。
      # 既定は全て true なので、未指定なら従来どおり全部入る。
      moduleConfig =
        {
          nvim = true;
          nodejs = true;
          oci = true;
          kubernetes = true;
          fonts = true;

          # version manager 群 (既定 false。opt-in で有効化する)。
          goenv = false;
          pyenv = false;
          rustup = false;
          nvm = false;
          plenv = false;
        }
        // (localConfig.modules or {});

      system = effectiveConfig.system;
      username = effectiveConfig.username;
      homePrefix = effectiveConfig.homePrefix or "/home";

      homeDirectory =
        if effectiveConfig ? homeDirectory then
          effectiveConfig.homeDirectory
        else
          "${homePrefix}/${username}";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      hmConfiguration =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit
              username
              homeDirectory
              localConfigLoaded
              localConfigPathString
              ;
            #wslgEnable = localConfig.wslgEnable or false;
            guiProfile = localConfig.guiProfile or "none";
            fcitx5Enable = localConfig.fcitx5Enable or false;
            googleDriveDir = localConfig.googleDriveDir or "~/Gdrive_kwatan";
            modules = moduleConfig;
          };

          modules = [
            ./home.nix
          ];
        };
    in
    {
      homeConfigurations =
        {
          default = hmConfiguration;
        }
        // lib.optionalAttrs (username != "default") {
          ${username} = hmConfiguration;
        };
    };
}
