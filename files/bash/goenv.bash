# Managed by Home Manager — goenv
# 本体は Nix で導入。go バージョンは ~/.goenv 配下に展開される。
export GOENV_ROOT="$HOME/.goenv"
if command -v goenv >/dev/null 2>&1; then
  eval "$(goenv init -)"
fi
