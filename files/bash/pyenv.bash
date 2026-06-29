# Managed by Home Manager — pyenv
# clone モード: pyenv.nix の activation が ~/.pyenv へ clone (python-build 同梱)。
# nix モード: pyenv は nix profile の PATH 上にある。
# どちらでも動くよう、~/.pyenv/bin があれば PATH に足してから init する。
# python バージョンは ~/.pyenv/versions に入る (pyenv install でソースからビルド。
# stdlib ビルドには libssl-dev/zlib1g-dev/libbz2-dev/libreadline-dev/libsqlite3-dev/
# libffi-dev/liblzma-dev 等の dev ライブラリが別途必要)。
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && path_prepend "$PYENV_ROOT/bin"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
