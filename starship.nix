{ ... }:

{
  programs.starship = {
    enable = true;
    #enableBashIntegration = true;
    enableBashIntegration = false;
  };

  home.file.".config/starship.toml".source =
    ./files/starship/starship.toml;
}
