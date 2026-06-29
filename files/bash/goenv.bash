# Managed by Home Manager — goenv
# goenv は nixpkgs に無いため本体は手動導入前提 (例: git clone ... ~/.goenv)。
# 導入済みのときだけ有効化する (未導入でもエラーにしない)。
export GOENV_ROOT="$HOME/.goenv"
if [ -d "$GOENV_ROOT/bin" ]; then
  path_prepend "$GOENV_ROOT/bin"
  if command -v goenv >/dev/null 2>&1; then
    eval "$(goenv init -)"
  fi
fi
