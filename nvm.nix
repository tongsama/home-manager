{ ... }:

{
  # nvm は nixpkgs に無いため本体は導入しない (手動導入前提: 例 git clone ... ~/.nvm)。
  # シェル統合のみ提供し、~/.nvm があるときだけ有効になる。
  home.file.".config/bash/hm-extra.d/nvm.bash".source = ./files/bash/nvm.bash;
}
