# Managed by Home Manager — nvm
# nvm は nixpkgs に無く、nvm.nix の activation が ~/.nvm へ clone する。
# clone 前/失敗時でも壊れないよう存在ガードする。
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
