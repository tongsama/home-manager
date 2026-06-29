# Managed by Home Manager — goenv
# clone モード: goenv.nix の activation が ~/.goenv へ clone。
# nix モード: goenv は nix profile の PATH 上にある (nixpkgs にあれば)。
# どちらでも動くよう、~/.goenv/bin があれば PATH に足してから init する。
export GOENV_ROOT="$HOME/.goenv"
[ -d "$GOENV_ROOT/bin" ] && path_prepend "$GOENV_ROOT/bin"
if command -v goenv >/dev/null 2>&1; then
  eval "$(goenv init -)"
fi
