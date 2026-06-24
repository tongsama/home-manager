{ pkgs, ... }:

let
  helm = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [
      helm-diff
    ];
  };
in
{
  home.packages = with pkgs; [
    kubectl
    helm
    helmfile
    k9s
  ];
}
