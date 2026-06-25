{ lib, config, pkgs, ... }:

let
  isWslg = config.my.gui.profile == "wslg-x11";

  layout = ":minimize,maximize,close";

  gtkSettings = ''
    [Settings]
    gtk-decoration-layout=${layout}
  '';
in
{
  config = lib.mkIf isWslg {
    home.file.".config/gtk-3.0/settings.ini".text = gtkSettings;
    home.file.".config/gtk-4.0/settings.ini".text = gtkSettings;

    home.activation.applyWslgGsettings =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        echo "applyWslgGsettings を有効化しています"

        if [ -x /usr/bin/gsettings ]; then
          gsettings_cmd=/usr/bin/gsettings
        elif command -v gsettings >/dev/null 2>&1; then
          gsettings_cmd="$(command -v gsettings)"
        else
          echo "[warn] gsettings not found; skip WSLg button-layout setup" >&2
          exit 0
        fi

        uid="$(${pkgs.coreutils}/bin/id -u)"
        user_bus="/run/user/$uid/bus"

        if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
          "$gsettings_cmd" set \
            org.gnome.desktop.wm.preferences \
            button-layout \
            '${layout}' || true
        elif [ -S "$user_bus" ]; then
          DBUS_SESSION_BUS_ADDRESS="unix:path=$user_bus" \
            "$gsettings_cmd" set \
              org.gnome.desktop.wm.preferences \
              button-layout \
              '${layout}' || true
        else
          echo "[warn] no user D-Bus session bus found at $user_bus; skip gsettings setup" >&2
          exit 0
        fi
      '';
  };
}
