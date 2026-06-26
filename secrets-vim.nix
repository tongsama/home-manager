{ lib, config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  repoDir = "${homeDir}/.config/home-manager";

  hmVimSecrets = pkgs.writeShellApplication {
    name = "hm-vim-secrets";

    runtimeInputs = with pkgs; [
      coreutils
      sops
      age
      python3
    ];

    text = ''
      set -eu

      repo="''${HM_HOME_MANAGER_REPO:-${repoDir}}"
      secrets_dir="$repo/secrets"
      plain_dir="$secrets_dir/plain-vim"
      plain_env="$plain_dir/secrets.env"
      secrets_file="$secrets_dir/vim.yaml"
      sops_config="$repo/.sops.yaml"
      age_key="$HOME/.config/sops/age/keys.txt"
      vimrc_secrets_template="$repo/files/vim/dotvimrc-secrets.template"
      vimrc_secrets_out="$HOME/.vimrc-secrets"

      usage() {
        cat <<'EOF'
Usage:
  hm-vim-secrets init
  hm-vim-secrets status
  hm-vim-secrets sync [--keep]
  hm-vim-secrets add
  hm-vim-secrets deploy [--soft]
  hm-vim-secrets edit

Files:
  plaintext input:
    secrets/plain-vim/secrets.env

  encrypted secret:
    secrets/vim.yaml

  template:
    files/vim/dotvimrc-secrets.template

  generated:
    ~/.vimrc-secrets

secrets.env format:
  OPENAI_API_KEY=sk-...
  ANTHROPIC_API_KEY=sk-ant-...
EOF
      }

      ensure_dirs() {
        mkdir -p "$plain_dir"
        mkdir -p "$(dirname "$age_key")"
      }

      ensure_plain_gitignore() {
        mkdir -p "$plain_dir"
        cat > "$plain_dir/.gitignore" <<'EOF'
*
!.gitignore
EOF
      }

      ensure_sops_config() {
        if [ -f "$sops_config" ]; then
          return 0
        fi

        if [ ! -f "$age_key" ]; then
          echo "age key not found: $age_key" >&2
          echo "Create or restore it first." >&2
          exit 1
        fi

        pub="$(age-keygen -y "$age_key")"

        cat > "$sops_config" <<EOF
keys:
  - &main_user $pub

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *main_user
EOF
      }

      require_age_key() {
        if [ ! -f "$age_key" ]; then
          echo "age key not found: $age_key" >&2
          exit 1
        fi
      }

      require_sops_config() {
        if [ ! -f "$sops_config" ]; then
          echo "sops config not found: $sops_config" >&2
          echo "Run: hm-vim-secrets init" >&2
          exit 1
        fi
      }

      require_template() {
        if [ ! -r "$vimrc_secrets_template" ]; then
          echo "vimrc secrets template not found: $vimrc_secrets_template" >&2
          exit 1
        fi
      }

      cmd_init() {
        ensure_dirs
        ensure_plain_gitignore
        ensure_sops_config

        echo "initialized vim secret paths"
        echo "plain input:      $plain_env"
        echo "encrypted secret: $secrets_file"
        echo "template:         $vimrc_secrets_template"
        echo "generated secrets: $vimrc_secrets_out"
      }

      cmd_status() {
        echo "repo:             $repo"
        echo "age key:          $age_key"
        echo "sops config:      $sops_config"
        echo "plain env:        $plain_env"
        echo "encrypted secret: $secrets_file"
        echo "template:         $vimrc_secrets_template"
        echo "generated secrets: $vimrc_secrets_out"
        echo

        [ -f "$age_key" ] && echo "OK age key exists" || echo "NG age key missing"
        [ -f "$sops_config" ] && echo "OK .sops.yaml exists" || echo "NG .sops.yaml missing"
        [ -f "$plain_env" ] && echo "OK plaintext env exists" || echo "-- plaintext env missing"
        [ -f "$secrets_file" ] && echo "OK encrypted secret exists" || echo "NG encrypted secret missing"
        [ -f "$vimrc_secrets_template" ] && echo "OK vimrc secrets template exists" || echo "NG vimrc secrets template missing"
        [ -f "$vimrc_secrets_out" ] && echo "OK generated ~/.vimrc-secrets exists" || echo "-- generated ~/.vimrc-secrets missing"
      }

      env_to_json() {
        input="$1"

        INPUT_ENV="$input" python3 <<'PY'
import json
import os
import pathlib
import re
import sys

path = pathlib.Path(os.environ["INPUT_ENV"])
data = {}

key_re = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
    line = raw.strip()

    if not line or line.startswith("#"):
        continue

    if line.startswith("export "):
        line = line[len("export "):].strip()

    if "=" not in line:
        print(f"{path}:{lineno}: invalid line: missing '='", file=sys.stderr)
        sys.exit(1)

    key, value = line.split("=", 1)
    key = key.strip()
    value = value.strip()

    if not key_re.match(key):
        print(f"{path}:{lineno}: invalid key: {key}", file=sys.stderr)
        sys.exit(1)

    if (
        (value.startswith('"') and value.endswith('"'))
        or (value.startswith("'") and value.endswith("'"))
    ):
        value = value[1:-1]

    data[key] = value

if not data:
    print(f"{path}: no secrets found", file=sys.stderr)
    sys.exit(1)

json.dump(data, sys.stdout)
PY
      }

      cmd_sync() {
        keep="0"

        if [ "''${1:-}" = "--keep" ]; then
          keep="1"
        fi

        ensure_dirs
        ensure_plain_gitignore
        #require_sops_config
        ensure_sops_config

        if [ ! -f "$plain_env" ]; then
          echo "plaintext env not found: $plain_env" >&2
          echo "Create it, or run: hm-vim-secrets add" >&2
          exit 1
        fi

        plain_json="$(mktemp)"
        encrypted_yaml="$(mktemp)"

        env_to_json "$plain_env" > "$plain_json"

        sops --encrypt \
          --input-type json \
          --output-type yaml \
          --config "$sops_config" \
          --filename-override "$secrets_file" \
          "$plain_json" > "$encrypted_yaml"

        install -m 600 "$encrypted_yaml" "$secrets_file"

        rm -f "$plain_json" "$encrypted_yaml"

        if [ "$keep" != "1" ]; then
          rm -f "$plain_env"
        fi

        echo "encrypted: $secrets_file"

        if [ "$keep" = "1" ]; then
          echo "kept plaintext: $plain_env"
        else
          echo "removed plaintext: $plain_env"
        fi
      }

      cmd_sync_if_present() {
        ensure_dirs
        ensure_plain_gitignore
      
        if [ ! -f "$plain_env" ]; then
          echo "no plaintext vim secrets found: $plain_env"
          return 0
        fi
      
        echo "plaintext vim secrets found; encrypting: $plain_env"
        cmd_sync
      }

      cmd_add() {
        ensure_dirs
        ensure_plain_gitignore

        cat > "$plain_env"
        chmod 600 "$plain_env"

        cmd_sync
      }

      render_vimrc() {
        require_age_key
        require_template

        if [ ! -f "$secrets_file" ]; then
          echo "encrypted secret not found: $secrets_file" >&2
          exit 1
        fi

        secrets_json="$(mktemp)"
        tmp_vimrc="$(mktemp)"

        sops --decrypt --output-type json "$secrets_file" > "$secrets_json"

        SECRETS_JSON="$secrets_json" \
        VIMRC_TEMPLATE="$vimrc_secrets_template" \
        VIMRC_OUT="$tmp_vimrc" \
        python3 <<'PY'
import json
import os
import pathlib
import re
import sys

secrets_path = pathlib.Path(os.environ["SECRETS_JSON"])
template_path = pathlib.Path(os.environ["VIMRC_TEMPLATE"])
out_path = pathlib.Path(os.environ["VIMRC_OUT"])

secrets = json.loads(secrets_path.read_text())
text = template_path.read_text()

placeholder_re = re.compile(r"@([A-Z_][A-Z0-9_]*)@")
placeholders = sorted(set(placeholder_re.findall(text)))

missing = [key for key in placeholders if key not in secrets]
if missing:
    print("missing secret values for placeholders:", file=sys.stderr)
    for key in missing:
        print(f"  @{key}@", file=sys.stderr)
    sys.exit(1)

def replace(match):
    key = match.group(1)
    return str(secrets[key])

out_path.write_text(placeholder_re.sub(replace, text))
PY

        install -m 600 "$tmp_vimrc" "$vimrc_secrets_out"

        rm -f "$secrets_json" "$tmp_vimrc"

        echo "deployed: $vimrc_secrets_out"
      }

      cmd_deploy() {
        soft="0"

        if [ "''${1:-}" = "--soft" ]; then
          soft="1"
        fi

        if [ "$soft" = "1" ]; then
          if [ ! -f "$age_key" ]; then
            echo "[warning] age key not found; skipping secrets deploy: $age_key" >&2
            exit 0
          fi

          if [ ! -f "$secrets_file" ]; then
            echo "[warning] encrypted vim secret not found; skipping secrets deploy: $secrets_file" >&2
            exit 0
          fi

          if [ ! -f "$vimrc_secrets_template" ]; then
            echo "[warning] vimrc secrets template not found; skipping secrets deploy: $vimrc_secrets_template" >&2
            exit 0
          fi
        fi

        render_vimrc
      }

      cmd_edit() {
        require_sops_config

        if [ ! -f "$secrets_file" ]; then
          echo "encrypted secret not found: $secrets_file" >&2
          echo "Create it with: hm-vim-secrets add" >&2
          exit 1
        fi

        sops --config "$sops_config" "$secrets_file"
      }

      case "''${1:-}" in
        init)
          shift
          cmd_init "$@"
          ;;
        status)
          shift
          cmd_status "$@"
          ;;
        sync)
          shift
          cmd_sync "$@"
          ;;
        sync-if-present)
          shift
          cmd_sync_if_present "$@"
          ;;
        add)
          shift
          cmd_add "$@"
          ;;
        deploy)
          shift
          cmd_deploy "$@"
          ;;
        edit)
          shift
          cmd_edit "$@"
          ;;
        ""|-h|--help|help)
          usage
          ;;
        *)
          echo "unknown command: $1" >&2
          usage >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  home.packages = [
    hmVimSecrets
  ];

  home.activation.deployVimrc =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${hmVimSecrets}/bin/hm-vim-secrets sync-if-present
      ${hmVimSecrets}/bin/hm-vim-secrets deploy --soft
    '';
}
