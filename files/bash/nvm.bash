# Managed by Home Manager — nvm
# nvm は nixpkgs に無いため本体は手動導入前提 (例: git clone ... ~/.nvm)。
# 導入済みのときだけ読み込む (未導入でもエラーにしない)。
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
