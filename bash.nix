{ lib, config, pkgs, googleDriveDir ? "~/Gdrive_kwatan", ... }:

let
  startMarker = "# >>> home-manager bash extras >>>";
  endMarker = "# <<< home-manager bash extras <<<";

  managedBashrcBlock =
    lib.concatStringsSep "\n" [
      startMarker
      "# Home Manager bash extras"
      ''[ -r "$HOME/.config/bash/hm-extra.bash" ] && . "$HOME/.config/bash/hm-extra.bash"''
      endMarker
    ] + "\n";
in
{
  home.file.".config/bash/hm-extra.bash".text = ''
    # Managed by Home Manager

    path_prepend() {
      case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
      esac
    }

    path_prepend "$HOME/Apps/bin"

    ##### extra aliases
    alias g='git'
    alias dc='docker compose'
    alias lla='ls -la'
    alias k9s='LANG=C k9s'

    ##### starship initialization
    if [ -n "$BASH_VERSION" ] && [ -x "${pkgs.starship}/bin/starship" ]; then
      eval "$("${pkgs.starship}/bin/starship" init bash)"
    fi

    ##### Google Drive directory detection (NIX_HM_GOOGLEDRIVE_DIR)
    # googleDriveDir が空でなく、その実体ディレクトリに1つ以上の
    # ファイル/ディレクトリが存在する場合のみ、指定された値そのものを
    # NIX_HM_GOOGLEDRIVE_DIR に入れる。そうでなければ環境変数を設定しない。
    __hm_gdrive_cfg="${googleDriveDir}"
    case "$__hm_gdrive_cfg" in
      "~")   __hm_gdrive_path="$HOME" ;;
      "~/"*) __hm_gdrive_path="$HOME/''${__hm_gdrive_cfg#~/}" ;;
      *)     __hm_gdrive_path="$__hm_gdrive_cfg" ;;
    esac
    if [ -n "$__hm_gdrive_cfg" ] \
      && [ -d "$__hm_gdrive_path" ] \
      && [ -n "$(ls -A "$__hm_gdrive_path" 2>/dev/null)" ]; then
      export NIX_HM_GOOGLEDRIVE_DIR="${googleDriveDir}"
    fi
    unset __hm_gdrive_cfg __hm_gdrive_path

    ##### Load Home Manager bash fragments
    if [ -d "$HOME/.config/bash/hm-extra.d" ]; then
      for f in "$HOME"/.config/bash/hm-extra.d/*.bash; do
        [ -r "$f" ] && . "$f"
      done
      unset f
    fi
  '';

  home.activation.ensureBashrcHomeManagerBlock =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      bashrc="${config.home.homeDirectory}/.bashrc"
      start_marker=${lib.escapeShellArg startMarker}
      end_marker=${lib.escapeShellArg endMarker}

      if [ ! -e "$bashrc" ]; then
        touch "$bashrc"
      fi

      block_file="$(mktemp)"
      tmp="$(mktemp)"

      cleanup() {
        rm -f "$block_file" "$tmp"
      }
      trap cleanup EXIT

      cat > "$block_file" <<'__HM_BASHRC_BLOCK__'
${managedBashrcBlock}__HM_BASHRC_BLOCK__

      if ${pkgs.gnugrep}/bin/grep -Fqx "$start_marker" "$bashrc"; then
        ${pkgs.gawk}/bin/awk \
          -v start="$start_marker" \
          -v end="$end_marker" \
          -v block_file="$block_file" '
            $0 == start {
              while ((getline line < block_file) > 0) {
                print line
              }
              close(block_file)
              in_block = 1
              next
            }

            $0 == end {
              in_block = 0
              next
            }

            !in_block {
              print
            }
          ' "$bashrc" > "$tmp"
      else
        cat "$bashrc" > "$tmp"

        # .bashrc が空じゃない場合だけ、区切りの空行を1つ入れる
        if [ -s "$bashrc" ]; then
          printf "\n" >> "$tmp"
        fi

        cat "$block_file" >> "$tmp"
      fi

      if ! cmp -s "$tmp" "$bashrc"; then
        cp "$bashrc" "$bashrc.hm-before-block-update" || true
        cat "$tmp" > "$bashrc"
      fi
    '';
}
