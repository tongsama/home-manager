# Managed by Home Manager — plenv
# clone モード: plenv.nix の activation が ~/.plenv (+ perl-build) へ clone。
# nix モード: plenv は nix profile の PATH 上にある (nixpkgs にあれば)。
# どちらでも動くよう、~/.plenv/bin があれば PATH に足してから init する。
export PLENV_ROOT="$HOME/.plenv"
[ -d "$PLENV_ROOT/bin" ] && path_prepend "$PLENV_ROOT/bin"
if command -v plenv >/dev/null 2>&1; then
  eval "$(plenv init -)"
fi
