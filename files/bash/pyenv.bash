# Managed by Home Manager — pyenv
# 本体は Nix で導入。python バージョンは ~/.pyenv 配下に展開される。
# (pyenv install でのビルドには別途 C コンパイラ等のビルド依存が必要)
export PYENV_ROOT="$HOME/.pyenv"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
