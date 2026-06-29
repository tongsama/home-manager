# Managed by Home Manager — nodenv
# clone モード: nodenv.nix の activation が ~/.nodenv (+ node-build) へ clone。
# nix モード: nodenv は nix profile の PATH 上にある (nixpkgs にあれば)。
# どちらでも動くよう、~/.nodenv/bin があれば PATH に足してから init する。
export NODENV_ROOT="$HOME/.nodenv"
[ -d "$NODENV_ROOT/bin" ] && path_prepend "$NODENV_ROOT/bin"
if command -v nodenv >/dev/null 2>&1; then
  eval "$(nodenv init -)"
fi
