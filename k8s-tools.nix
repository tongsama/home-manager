{ pkgs, lib, config, ... }:

let
  helm = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [
      helm-diff
    ];
  };
in
lib.mkIf config.my.modules.kubernetes {
  home.packages = with pkgs; [
    kubectl
    helm
    helmfile
    k9s
  ];
}
