# Managed by Home Manager — nodenv
# nodenv は nixpkgs に無く、nodenv.nix の activation が ~/.nodenv (+ node-build) へ clone する。
# clone 前/失敗時でも壊れないよう存在ガードする。
export NODENV_ROOT="$HOME/.nodenv"
if [ -d "$NODENV_ROOT/bin" ]; then
  path_prepend "$NODENV_ROOT/bin"
  if command -v nodenv >/dev/null 2>&1; then
    eval "$(nodenv init -)"
  fi
fi
