{ lib, config, pkgs, ... }:

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

    alias g='git'
    alias dc='docker compose'
    alias lla='ls -la'
    alias k9s='LANG=C k9s'

    #### starship initialization
    if command -v starship >/dev/null 2>&1; then
      eval "$(starship init bash)"
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
