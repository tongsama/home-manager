# Managed by Home Manager — plenv
# plenv は nixpkgs に無いため本体は手動導入前提 (例: git clone ... ~/.plenv)。
# 導入済みのときだけ有効化する (未導入でもエラーにしない)。
export PLENV_ROOT="$HOME/.plenv"
if [ -d "$PLENV_ROOT/bin" ]; then
  path_prepend "$PLENV_ROOT/bin"
  if command -v plenv >/dev/null 2>&1; then
    eval "$(plenv init -)"
  fi
fi
