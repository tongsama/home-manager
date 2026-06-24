{ lib, config, pkgs, ... }:

let
  repoDir = "${config.home.homeDirectory}/.config/home-manager";
  ociSessionDir = "${config.home.homeDirectory}/.oci/sessions/DEFAULT";
  ociPrivateKeyName = "oci_api_key.pem";

  mergePlainOciPy = pkgs.writeText "merge-plain-oci-secrets.py" ''
    import json
    import pathlib
    import sys

    old_json = pathlib.Path(sys.argv[1])
    plain_key = pathlib.Path(sys.argv[2])
    out_json = pathlib.Path(sys.argv[3])

    if old_json.exists() and old_json.stat().st_size > 0:
        data = json.loads(old_json.read_text())
    else:
        data = {}

    if plain_key.exists():
        data["oci_api_key.pem"] = plain_key.read_text()
        print("imported: oci_api_key.pem", file=sys.stderr)
    else:
        print(f"plain key not found: {plain_key}", file=sys.stderr)

    out_json.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
  '';

  deployOciSecretsPy = pkgs.writeText "deploy-oci-secrets.py" ''
    import json
    import os
    import pathlib
    import sys

    session_dir = pathlib.Path(sys.argv[1])
    key_name = sys.argv[2]

    data = json.load(sys.stdin)

    if key_name not in data:
        print(f"secret missing: {key_name}", file=sys.stderr)
        sys.exit(1)

    value = data[key_name]

    if not isinstance(value, str):
        print(f"secret is not a string: {key_name}", file=sys.stderr)
        sys.exit(1)

    session_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(session_dir, 0o700)

    target = session_dir / key_name
    tmp = session_dir / f".{key_name}.tmp"

    try:
        tmp.unlink()
    except FileNotFoundError:
        pass

    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)

    with os.fdopen(fd, "w") as f:
        f.write(value)
        if not value.endswith("\n"):
            f.write("\n")

    os.chmod(tmp, 0o600)
    os.replace(tmp, target)

    print(f"deployed: {target}", file=sys.stderr)
  '';

  hmOciSecrets = pkgs.writeShellApplication {
    name = "hm-oci-secrets";

    runtimeInputs = with pkgs; [
      sops
      age
      coreutils
      findutils
      gnugrep
      python3
    ];

    text = ''
      set -eu

      repo="''${HM_HOME_MANAGER_REPO:-${repoDir}}"
      secrets_dir="$repo/secrets"
      plain_dir="$secrets_dir/plain-oci"
      plain_key="$plain_dir/oci_api_key.pem"
      secrets_file="$secrets_dir/oci.yaml"
      sops_config="$repo/.sops.yaml"
      age_key="$HOME/.config/sops/age/keys.txt"
      session_dir="${ociSessionDir}"
      key_name="${ociPrivateKeyName}"

      usage() {
        cat <<'EOF'
Usage:
  hm-oci-secrets init
  hm-oci-secrets status
  hm-oci-secrets sync [--keep]
  hm-oci-secrets add
  hm-oci-secrets deploy [--soft]
  hm-oci-secrets edit

Examples:
  hm-oci-secrets init
  cp ~/.oci/sessions/DEFAULT/oci_api_key.pem ~/.config/home-manager/secrets/plain-oci/
  hm-oci-secrets sync

  hm-oci-secrets add
  # paste private key, then Ctrl-D
EOF
      }

      ensure_dirs() {
        mkdir -p "$secrets_dir" "$plain_dir" "$HOME/.config/sops/age"
        chmod 700 "$HOME/.config/sops" "$HOME/.config/sops/age" 2>/dev/null || true

        if [ ! -e "$plain_dir/.gitignore" ]; then
          cat > "$plain_dir/.gitignore" <<'EOF'
*
!.gitignore
EOF
        fi
      }

      public_age_key() {
        grep -m 1 -o 'age1[0-9a-z]*' "$age_key"
      }

      cmd_init() {
        ensure_dirs

        if [ ! -e "$age_key" ]; then
          age-keygen -o "$age_key"
          chmod 600 "$age_key"
        fi

        pub="$(public_age_key)"

        if [ ! -e "$sops_config" ]; then
          cat > "$sops_config" <<EOF
keys:
  - &kwatanabe_nix $pub

creation_rules:
  - path_regex: secrets/.*\\.yaml$
    key_groups:
      - age:
          - *kwatanabe_nix
EOF
        fi

        echo
        echo "OK: age key is here:"
        echo "  $age_key"
        echo
        echo "Public recipient:"
        echo "  $pub"
        echo
        echo "Plaintext OCI import directory:"
        echo "  $plain_dir"
      }

      require_age_key() {
        if [ ! -r "$age_key" ]; then
          echo "age key not found:" >&2
          echo "  $age_key" >&2
          echo >&2
          echo "復元したい場合は、バックアップしてあるage秘密鍵をここに置いて:" >&2
          echo "  $age_key" >&2
          echo >&2
          echo "新しい環境として作るなら:" >&2
          echo "  hm-oci-secrets init" >&2
          return 1
        fi
      }

      cmd_status() {
        echo "repo:         $repo"
        echo "age key:      $age_key"
        echo "sops config:  $sops_config"
        echo "secrets file: $secrets_file"
        echo "plain key:    $plain_key"
        echo "deploy path:  $session_dir/$key_name"
        echo

        if [ -r "$age_key" ]; then
          echo "age key: OK"
        else
          echo "age key: MISSING"
        fi

        if [ -r "$sops_config" ]; then
          echo ".sops.yaml: OK"
        else
          echo ".sops.yaml: MISSING"
        fi

        if [ -r "$secrets_file" ]; then
          if SOPS_AGE_KEY_FILE="$age_key" sops --decrypt --output-type json "$secrets_file" >/dev/null 2>&1; then
            echo "decrypt: OK"
          else
            echo "decrypt: FAILED"
          fi
        else
          echo "secrets/oci.yaml: MISSING"
        fi

        if [ -r "$plain_key" ]; then
          echo "plain pending key: YES"
        else
          echo "plain pending key: NO"
        fi

        if [ -r "$session_dir/$key_name" ]; then
          echo "deployed key: OK"
        else
          echo "deployed key: MISSING"
        fi
      }

      cmd_sync() {
        keep=0

        if [ "''${1:-}" = "--keep" ]; then
          keep=1
        fi

        ensure_dirs
        require_age_key

        if [ ! -r "$plain_key" ]; then
          echo "No plaintext OCI private key found:"
          echo "  $plain_key"
          return 0
        fi

        tmpdir="$(mktemp -d)"
        old_json="$tmpdir/old.json"
        merged_json="$tmpdir/merged.json"
        encrypted_yaml="$tmpdir/oci.yaml"

        cleanup() {
          rm -rf "$tmpdir"
        }
        trap cleanup EXIT

        export SOPS_AGE_KEY_FILE="$age_key"

        if [ -s "$secrets_file" ]; then
          sops --decrypt --output-type json "$secrets_file" > "$old_json"
        else
          printf '{}\n' > "$old_json"
        fi

        python3 ${mergePlainOciPy} "$old_json" "$plain_key" "$merged_json"

        sops --encrypt \
          --config "$sops_config" \
          --input-type json \
          --output-type yaml \
          --filename-override "$secrets_file" \
          "$merged_json" > "$encrypted_yaml"

        mv "$encrypted_yaml" "$secrets_file"
        chmod 600 "$secrets_file" 2>/dev/null || true

        if [ "$keep" -eq 0 ]; then
          shred -u "$plain_key" 2>/dev/null || rm -f "$plain_key"
        fi

        echo "Updated encrypted OCI secrets:"
        echo "  $secrets_file"
      }

      cmd_add() {
        ensure_dirs

        umask 077
        cat > "$plain_key"
        chmod 600 "$plain_key"

        cmd_sync
      }

      cmd_deploy() {
        soft=0

        if [ "''${1:-}" = "--soft" ]; then
          soft=1
        fi

        if [ ! -r "$age_key" ]; then
          cat >&2 <<EOF

[hm-oci-secrets] age key がまだ無いのでOCI秘密鍵の復元をスキップしたよ。

復元したい場合:
  mkdir -p ~/.config/sops/age
  chmod 700 ~/.config/sops ~/.config/sops/age
  cp <backup>/keys.txt ~/.config/sops/age/keys.txt
  chmod 600 ~/.config/sops/age/keys.txt
  home-manager switch --flake ~/.config/home-manager#kwatanabe-nix -b backup

新しい環境として作り直す場合:
  hm-oci-secrets init
  cp ~/.oci/sessions/DEFAULT/oci_api_key.pem ~/.config/home-manager/secrets/plain-oci/
  hm-oci-secrets sync
  home-manager switch --flake ~/.config/home-manager#kwatanabe-nix -b backup

注意:
  元のage秘密鍵が無いと、既存の secrets/oci.yaml は復号できないよ。
EOF

          if [ "$soft" -eq 1 ]; then
            exit 0
          else
            exit 1
          fi
        fi

        if [ ! -r "$secrets_file" ]; then
          cat >&2 <<EOF

[hm-oci-secrets] secrets/oci.yaml がまだ無いのでOCI秘密鍵の復元をスキップしたよ。

初期化:
  hm-oci-secrets init

鍵を追加:
  cp ~/.oci/sessions/DEFAULT/oci_api_key.pem ~/.config/home-manager/secrets/plain-oci/
  hm-oci-secrets sync
EOF

          if [ "$soft" -eq 1 ]; then
            exit 0
          else
            exit 1
          fi
        fi

        export SOPS_AGE_KEY_FILE="$age_key"

        sops --decrypt --output-type json "$secrets_file" \
          | python3 ${deployOciSecretsPy} "$session_dir" "$key_name"
      }

      cmd_edit() {
        ensure_dirs
        require_age_key

        export SOPS_AGE_KEY_FILE="$age_key"

        if [ ! -e "$secrets_file" ]; then
          tmpdir="$(mktemp -d)"
          plain_json="$tmpdir/plain.json"
          encrypted_yaml="$tmpdir/oci.yaml"

          printf '{}\n' > "$plain_json"

          sops --encrypt \
            --config "$sops_config" \
            --input-type json \
            --output-type yaml \
            --filename-override "$secrets_file" \
            "$plain_json" > "$encrypted_yaml"

          mv "$encrypted_yaml" "$secrets_file"
          rm -rf "$tmpdir"
        fi

        sops "$secrets_file"
      }

      cmd="''${1:-help}"
      shift || true

      case "$cmd" in
        init|bootstrap)
          cmd_init "$@"
          ;;
        status)
          cmd_status "$@"
          ;;
        sync)
          cmd_sync "$@"
          ;;
        add)
          cmd_add "$@"
          ;;
        deploy)
          cmd_deploy "$@"
          ;;
        edit)
          cmd_edit "$@"
          ;;
        help|-h|--help)
          usage
          ;;
        *)
          echo "unknown command: $cmd" >&2
          usage >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  home.packages = [
    hmOciSecrets
  ];

  home.activation.deployOciPrivateKey =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      set -eu

      if [ -f "${repoDir}/secrets/plain-oci/oci_api_key.pem" ]; then
        ${hmOciSecrets}/bin/hm-oci-secrets sync
      fi

      ${hmOciSecrets}/bin/hm-oci-secrets deploy --soft
    '';
}

