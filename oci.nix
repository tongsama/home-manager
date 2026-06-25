{ lib, config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  repoDir = "${homeDir}/.config/home-manager";

  installOciPublicFiles = pkgs.writeShellApplication {
    name = "install-oci-public-files";

    runtimeInputs = with pkgs; [
      coreutils
      gnused
    ];

    text = ''
      set -eu

      oci_dir="$HOME/.oci"
      session_dir="$HOME/.oci/sessions/DEFAULT"

      config_template="${repoDir}/files/oci/config.template"
      public_key_src="${repoDir}/files/oci/sessions/DEFAULT/oci_api_key_public.pem"

      if [ ! -r "$config_template" ]; then
        echo "OCI config template not found: $config_template" >&2
        exit 1
      fi

      if [ ! -r "$public_key_src" ]; then
        echo "OCI public key not found: $public_key_src" >&2
        exit 1
      fi

      mkdir -p "$session_dir"

      chmod 700 "$oci_dir"
      chmod 700 "$HOME/.oci/sessions"
      chmod 700 "$session_dir"

      tmp_config="$(mktemp)"

      sed \
        -e "s#@HOME_DIR@#${homeDir}#g" \
        "$config_template" > "$tmp_config"

      install -m 600 "$tmp_config" "$oci_dir/config"
      rm -f "$tmp_config"

      install -m 644 "$public_key_src" "$session_dir/oci_api_key_public.pem"
    '';
  };
in
{
  home.packages = with pkgs; [
    oci-cli
    installOciPublicFiles
  ];

  home.activation.installOciPublicFiles =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${installOciPublicFiles}/bin/install-oci-public-files
    '';
}
