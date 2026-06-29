{ ... }:

{
  # goenv は nixpkgs に無いため本体は導入しない (手動導入前提: 例 git clone ... ~/.goenv)。
  # シェル統合のみ提供し、~/.goenv があるときだけ有効になる。
  home.file.".config/bash/hm-extra.d/goenv.bash".source = ./files/bash/goenv.bash;
}
