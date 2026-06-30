{ lib, config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;

  okeKubeconfig = pkgs.writeShellApplication {
    name = "oke-kubeconfig";

    runtimeInputs = with pkgs; [
      oci-cli
      kubectl
      coreutils
    ];

    text = ''
      set -eu

      env_file="$HOME/.config/oke/default.env"

      if [ ! -r "$env_file" ]; then
        echo "OKE env file not found: $env_file" >&2
        exit 1
      fi

      # shellcheck disable=SC1090
      . "$env_file"

      : "''${OCI_CLI_PROFILE:?OCI_CLI_PROFILE is required}"
      : "''${OCI_REGION:?OCI_REGION is required}"
      : "''${OKE_CLUSTER_ID:?OKE_CLUSTER_ID is required}"
      : "''${OKE_KUBE_ENDPOINT:?OKE_KUBE_ENDPOINT is required}"
      : "''${KUBECONFIG_PATH:?KUBECONFIG_PATH is required}"

      kubeconfig_path="$(eval echo "$KUBECONFIG_PATH")"

      mkdir -p "$(dirname "$kubeconfig_path")"
      chmod 700 "$(dirname "$kubeconfig_path")"

      echo "Generating OKE kubeconfig..."
      echo "  cluster:       $OKE_CLUSTER_ID"
      echo "  region:        $OCI_REGION"
      echo "  profile:       $OCI_CLI_PROFILE"
      echo "  kube endpoint: $OKE_KUBE_ENDPOINT"
      echo "  public memo:   ''${OKE_PUBLIC_ENDPOINT:-}"
      echo "  file:          $kubeconfig_path"

      OCI_CLI_PROFILE="$OCI_CLI_PROFILE" \
        oci ce cluster create-kubeconfig \
          --cluster-id "$OKE_CLUSTER_ID" \
          --file "$kubeconfig_path" \
          --region "$OCI_REGION" \
          --token-version 2.0.0 \
          --kube-endpoint "$OKE_KUBE_ENDPOINT" \
      #--overwrite

      chmod 600 "$kubeconfig_path"

      echo
      echo "kubeconfig generated:"
      echo "  $kubeconfig_path"
      echo
      kubectl --kubeconfig "$kubeconfig_path" config current-context || true
    '';
  };
in
{
  home.packages = with pkgs; [
    okeKubeconfig
  ];

  home.file.".config/oke/default.env".text = ''
    OCI_CLI_PROFILE=DEFAULT
    OCI_REGION=ap-osaka-1

    OKE_CLUSTER_ID=ocid1.cluster.oc1.ap-osaka-1.aaaaaaaariaxk6h4yfjukl6hgfquv5etawmkmhgqgsd6mavn3ce45efv5n3q
    OKE_KUBE_ENDPOINT=PUBLIC_ENDPOINT

    # memo only
    OKE_PUBLIC_ENDPOINT=138.2.37.238:6443

    KUBECONFIG_PATH=$HOME/.kube/config
  '';

  home.activation.generateOkeKubeconfig =
    lib.hm.dag.entryAfter [ "deployOciPrivateKey" "linkGeneration" ] ''
      echo "Generating OKE kubeconfig during Home Manager activation..."

      if ${okeKubeconfig}/bin/oke-kubeconfig; then
        echo "OKE kubeconfig generated."
      else
        echo "[warning] OKE kubeconfig generation failed; continuing Home Manager activation." >&2
        echo "[warning] You can retry manually with: oke-kubeconfig" >&2
      fi
    '';
}
