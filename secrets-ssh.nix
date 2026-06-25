{ lib, config, pkgs, ... }:

let
  repoDir = "${config.home.homeDirectory}/.config/home-manager";

  mergePlainSshPy = pkgs.writeText "merge-plain-ssh-secrets.py" ''
    import json
    import pathlib
    import re
    import sys

    old_json = pathlib.Path(sys.argv[1])
    plain_dir = pathlib.Path(sys.argv[2])
    out_json = pathlib.Path(sys.argv[3])

    if old_json.exists() and old_json.stat().st_size > 0:
        data = json.loads(old_json.read_text())
    else:
        data = {}

    name_re = re.compile(r"^[A-Za-z0-9._-]+$")

    imported = []

    for path in sorted(plain_dir.iterdir()):
        if not path.is_file():
            continue
        if path.name.startswith("."):
            continue
        if path.name.endswith(".pub"):
            print(f"skip public key: {path.name}", file=sys.stderr)
            continue
        if not name_re.match(path.name) or "/" in path.name:
            print(f"skip unsafe filename: {path.name}", file=sys.stderr)
            continue

        data[path.name] = path.read_text()
        imported.append(path.name)

    out_json.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")

    for name in imported:
        print(f"imported: {name}", file=sys.stderr)
  '';

  deploySshSecretsPy = pkgs.writeText "deploy-ssh-secrets.py" ''
    import json
    import os
    import pathlib
    import re
    import sys

    ssh_dir = pathlib.Path(sys.argv[1])
    data = json.load(sys.stdin)

    name_re = re.compile(r"^[A-Za-z0-9._-]+$")

    ssh_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(ssh_dir, 0o700)

    for name, value in sorted(data.items()):
        if not isinstance(value, str):
            print(f"skip non-string secret: {name}", file=sys.stderr)
            continue

        if name.startswith(".") or not name_re.match(name) or "/" in name:
            print(f"skip unsafe secret name: {name}", file=sys.stderr)
            continue

        target = ssh_dir / name
        tmp = ssh_dir / f".{name}.tmp"

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

  hmSshSecrets = pkgs.writeShellApplication {
    name = "hm-ssh-secrets";

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
      plain_dir="$secrets_dir/plain-ssh"
      secrets_file="$secrets_dir/ssh.yaml"
      sops_config="$repo/.sops.yaml"
      age_key="$HOME/.config/sops/age/keys.txt"
      ssh_dir="$HOME/.ssh"

      usage() {
        cat <<'EOF'
      Usage:
        hm-ssh-secrets init
        hm-ssh-secrets status
        hm-ssh-secrets sync [--keep]
        hm-ssh-secrets add <key-name>
        hm-ssh-secrets deploy [--soft]
        hm-ssh-secrets edit

      Examples:
        hm-ssh-secrets init
        cp ~/.ssh/id_rsa_new ~/.config/home-manager/secrets/plain-ssh/
        hm-ssh-secrets sync

        hm-ssh-secrets add id_rsa_new
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
        grep -o 'age1[0-9a-z]*' "$age_key" | head -n 1
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
        - &main_user $pub

      creation_rules:
        - path_regex: secrets/.*\\.yaml$
          key_groups:
            - age:
                - *main_user
      EOF
        fi

        echo
        echo "OK: age key is here:"
        echo "  $age_key"
        echo
        echo "Public recipient:"
        echo "  $pub"
        echo
        echo "Plaintext import directory:"
        echo "  $plain_dir"
      }

      cmd_status() {
        echo "repo:         $repo"
        echo "age key:      $age_key"
        echo "sops config:  $sops_config"
        echo "secrets file: $secrets_file"
        echo "plain dir:    $plain_dir"
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
          echo "secrets/ssh.yaml: MISSING"
        fi

        if [ -d "$plain_dir" ]; then
          count="$(find "$plain_dir" -maxdepth 1 -type f ! -name '.gitignore' | wc -l)"
          echo "plain pending files: $count"
        fi
      }

      require_age_key() {
        if [ ! -r "$age_key" ]; then
          echo "age key not found:" >&2
          echo "  $age_key" >&2
          echo >&2
          echo "新規環境ならまず:" >&2
          echo "  hm-ssh-secrets init" >&2
          echo >&2
          echo "既存の暗号化済み secrets/ssh.yaml を復号したいなら、" >&2
          echo "元の age private key をここに置いて:" >&2
          echo "  $age_key" >&2
          echo >&2
          echo "注意: 元のage秘密鍵がない場合、既存のsecrets/ssh.yamlは復号できない。" >&2
          return 1
        fi
      }

      cmd_sync() {
        keep=0
        if [ "''${1:-}" = "--keep" ]; then
          keep=1
        fi

        ensure_dirs
        require_age_key

        if ! find "$plain_dir" -maxdepth 1 -type f ! -name '.gitignore' -print -quit | grep -q .; then
          echo "No plaintext SSH keys found in:"
          echo "  $plain_dir"
          return 0
        fi

        tmpdir="$(mktemp -d)"
        trap 'rm -rf "$tmpdir"' EXIT

        old_json="$tmpdir/old.json"
        merged_json="$tmpdir/merged.json"
        encrypted_yaml="$tmpdir/ssh.yaml"

        export SOPS_AGE_KEY_FILE="$age_key"

        if [ -s "$secrets_file" ]; then
          sops --decrypt --output-type json "$secrets_file" > "$old_json"
        else
          printf '{}\n' > "$old_json"
        fi

        python3 ${mergePlainSshPy} "$old_json" "$plain_dir" "$merged_json"

        # --filename-override により、stdin/temp経由でも .sops.yaml の path_regex を効かせる
        sops --encrypt \
          --config "$sops_config" \
          --input-type json \
          --output-type yaml \
          --filename-override "$secrets_file" \
          "$merged_json" > "$encrypted_yaml"

        mv "$encrypted_yaml" "$secrets_file"
        chmod 600 "$secrets_file" 2>/dev/null || true

        if [ "$keep" -eq 0 ]; then
          while IFS= read -r -d "" f; do
            shred -u "$f" 2>/dev/null || rm -f "$f"
          done < <(find "$plain_dir" -maxdepth 1 -type f ! -name '.gitignore' -print0)
        fi

        echo "Updated encrypted secrets:"
        echo "  $secrets_file"
      }

      cmd_add() {
        name="''${1:-}"

        if [ -z "$name" ]; then
          echo "key name is required" >&2
          echo "example: hm-ssh-secrets add id_rsa_new" >&2
          exit 1
        fi

        case "$name" in
          .*|*/*)
            echo "unsafe key name: $name" >&2
            exit 1
            ;;
        esac

        ensure_dirs

        target="$plain_dir/$name"

        umask 077
        cat > "$target"
        chmod 600 "$target"

        cmd_sync
      }

      cmd_deploy() {
        soft=0

        if [ "''${1:-}" = "--soft" ]; then
          soft=1
        fi

        if [ ! -r "$age_key" ]; then
          cat >&2 <<EOF

      [hm-ssh-secrets] age key がまだ無いのでSSH秘密鍵の復元をスキップしたよ。

      復元したい場合:
        mkdir -p ~/.config/sops/age
        chmod 700 ~/.config/sops ~/.config/sops/age
        cp <backup>/keys.txt ~/.config/sops/age/keys.txt
        chmod 600 ~/.config/sops/age/keys.txt
        home-manager switch -b backup

      新しい環境として作り直す場合:
        hm-ssh-secrets init
        cp <private-keys> ~/.config/home-manager/secrets/plain-ssh/
        hm-ssh-secrets sync
        home-manager switch -b backup

      注意:
        元のage秘密鍵が無いと、既存の secrets/ssh.yaml は復号できないよ。
      EOF

          if [ "$soft" -eq 1 ]; then
            exit 0
          else
            exit 1
          fi
        fi

        if [ ! -r "$secrets_file" ]; then
          cat >&2 <<EOF

      [hm-ssh-secrets] secrets/ssh.yaml がまだ無いのでSSH秘密鍵の復元をスキップしたよ。

      初期化:
        hm-ssh-secrets init

      鍵を追加:
        cp ~/.ssh/id_rsa_xxx ~/.config/home-manager/secrets/plain-ssh/
        hm-ssh-secrets sync
      EOF

          if [ "$soft" -eq 1 ]; then
            exit 0
          else
            exit 1
          fi
        fi

        export SOPS_AGE_KEY_FILE="$age_key"

        sops --decrypt --output-type json "$secrets_file" \
          | python3 ${deploySshSecretsPy} "$ssh_dir"
      }

      cmd_edit() {
        ensure_dirs
        require_age_key
      
        export SOPS_AGE_KEY_FILE="$age_key"
      
        if [ ! -e "$secrets_file" ]; then
          tmpdir="$(mktemp -d)"
          plain_json="$tmpdir/plain.json"
          encrypted_yaml="$tmpdir/ssh.yaml"
      
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
    hmSshSecrets
  ];

  home.activation.deploySshPrivateKeys =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      # plain-ssh にファイルが置かれていたら、switch時に自動で暗号化へ取り込む
      if [ -d "${repoDir}/secrets/plain-ssh" ]; then
        if ${pkgs.findutils}/bin/find "${repoDir}/secrets/plain-ssh" -maxdepth 1 -type f ! -name '.gitignore' -print -quit | ${pkgs.gnugrep}/bin/grep -q .; then
          ${hmSshSecrets}/bin/hm-ssh-secrets sync
        fi
      fi

      # 復元できない環境では案内だけ出してswitch自体は継続
      ${hmSshSecrets}/bin/hm-ssh-secrets deploy --soft
    '';
}
