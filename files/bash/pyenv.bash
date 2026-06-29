# Managed by Home Manager — pyenv
# pyenv は pyenv.nix の activation が ~/.pyenv へ clone する (python-build 同梱)。
# clone 前/失敗時でも壊れないよう存在ガードする。
# python バージョンは ~/.pyenv/versions に入る (pyenv install でソースからビルド)。
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
  path_prepend "$PYENV_ROOT/bin"
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
  fi
fi
