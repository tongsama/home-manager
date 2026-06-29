{ ... }:

{
  # plenv は nixpkgs に無いため本体は導入しない (手動導入前提: 例 git clone ... ~/.plenv)。
  # シェル統合のみ提供し、~/.plenv があるときだけ有効になる。
  home.file.".config/bash/hm-extra.d/plenv.bash".source = ./files/bash/plenv.bash;
}
