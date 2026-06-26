# Troubleshooting / 検証コマンド

## Troubleshooting

### `su -` 後にStarshipが効かない

確認:

```bash
echo "SHELL=$SHELL"
echo "0=$0"
echo "PATH=$PATH"
command -v bash
command -v starship || echo "starship not found"
ls -la ~/.bash_profile ~/.bash_login ~/.profile ~/.bashrc 2>/dev/null

grep -n "hm-extra" ~/.bashrc
grep -n "starship" ~/.config/bash/hm-extra.bash

echo "$-"
echo "$STARSHIP_SHELL"
echo "$PROMPT_COMMAND"
echo "$PS1"
```

`~/.profile` では `.bashrc` が先に読み込まれ、Nix profile読み込みが後になることがある。

その場合、`.bashrc` から `hm-extra.bash` が読まれた時点では、まだ `starship` がPATHにいない。
このリポジトリでは、`hm-extra.bash` 内で `${pkgs.starship}/bin/starship` を絶対パスで呼ぶことで回避している。

### fcitx5が自動起動しない

WSLg環境では、fcitx5起動処理は `programs.bash.initExtra` ではなく、以下のfragmentから読み込む。

```text
~/.config/bash/hm-extra.d/fcitx5-wslg.bash
```

確認:

```bash
grep -n "hm-extra.d" ~/.config/bash/hm-extra.bash
ls -la ~/.config/bash/hm-extra.d/
cat ~/.config/bash/hm-extra.d/fcitx5-wslg.bash
```

新しいbashを開き直して確認する。

```bash
pgrep -a fcitx5
```

手動起動:

```bash
fcitx5 -d --disable=wayland,waylandim
```

### WSLgでfcitx5が効かない

WSLgでは、fcitx5自体は `--disable=wayland,waylandim` でWayland frontendを使わず、
GTK IM module / XIM 側へ寄せる。
（`GDK_BACKEND=x11` の強制は現在無効化。詳細は [gui-input.md](gui-input.md) の「WSLg + fcitx5」注記を参照）

確認:

```bash
echo "$GDK_BACKEND"
echo "$QT_QPA_PLATFORM"
echo "$GTK_IM_MODULE"
echo "$QT_IM_MODULE"
echo "$XMODIFIERS"
```

期待値:

```text
x11
xcb
fcitx
fcitx
@im=fcitx
```

fcitx5起動確認:

```bash
pgrep -a fcitx5
```

期待例:

```text
fcitx5 -d --disable=wayland,waylandim
```

対象アプリを同じbashから起動して確認する。

```bash
gvim
```

### WSLgのウィンドウ装飾が変わらない

確認:

```bash
cat ~/.config/gtk-3.0/settings.ini
cat ~/.config/gtk-4.0/settings.ini
```

期待値:

```ini
[Settings]
gtk-decoration-layout=:minimize,maximize,close
```

`gsettings` の値も確認する。

```bash
gsettings get org.gnome.desktop.wm.preferences button-layout
```

WSLg環境では通常のGNOMEデスクトップセッションが無いため、`gsettings` の値だけで判断しない。

`/run/user/$UID/bus` があるか確認する。

```bash
ls -l /run/user/$(id -u)/bus
```

あれば、Home Manager switch時にこのbus経由で `gsettings set` を試みる。

### `dbus-run-session` が失敗する

WSL2環境では、`dbus-run-session` で一時session busを起動しようとすると、以下のようなエラーになることがある。

```text
dbus-run-session: failed to execute message bus daemon 'dbus-daemon': No such file or directory
```

または:

```text
Failed to open "/etc/dbus-1/session.conf": No such file or directory
```

このリポジトリでは、WSLg設定で `dbus-run-session` は使わない。

代わりに、既存のuser busがあれば以下を使う。

```bash
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
```

`/run/user/$UID/at-spi/bus` は使わない。

### Vimが `~/.vimrc` を読まない

このリポジトリでは、`programs.vim` は使わない。

`programs.vim` を使うと、Home Managerがcustomized Vimを生成し、通常の `~/.vimrc` を読まないことがある。

確認:

```bash
vim +'scriptnames' +qa 2>&1 | grep -E 'vimrc|plug.vim'
```

期待:

```text
~/.vimrc
~/.vim/autoload/plug.vim
```

### vim-plugが読まれない

確認:

```bash
test -e ~/.vim/autoload/plug.vim && echo ok
vim +'echo exists("*plug#begin")' +qa
```

期待値:

```text
ok
1
```

`~/.vimrc` が読まれていない場合は、`vim.nix` で `programs.vim` を使っていないか確認する。

### Vim secretのplaceholderが足りない

`files/vim/dotvimrc-secrets.template` にあるplaceholderに対応するkeyが `secrets/vim.yaml` に無い場合、`hm-vim-secrets deploy` は失敗する。

例:

```text
missing secret values for placeholders:
  @OPENAI_API_KEY@
```

対応方法:

```bash
hm-vim-secrets edit
```

暗号化済みsecretにkeyを追加する。

```yaml
OPENAI_API_KEY: sk-...
```

反映:

```bash
hm-vim-secrets deploy
```

または:

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### Vim secretを追加したい

平文の一時ファイルを置く。

```bash
cat > secrets/plain-vim/secrets.env <<'EOF'
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx
EOF

home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

switch時に自動で `secrets/vim.yaml` に暗号化される。
平文の `secrets.env` は削除される。

暗号化済みを直接編集する場合:

```bash
hm-vim-secrets edit
hm-vim-secrets deploy
```

### secrets.envが残ったままになる

通常、`home-manager switch` 時に `secrets/plain-vim/secrets.env` が存在すると、自動で暗号化されて削除される。

残っている場合は手動で確認する。

```bash
hm-vim-secrets sync-if-present
```

age keyが無い場合は暗号化できない。

```bash
ls -la ~/.config/sops/age/keys.txt
```

### Nixで入れたnpmで `npm install -g` が失敗する

Nixで入れた `nodejs` の `npm` で以下を実行すると、失敗することがある。

```bash
npm install -g yarn
```

原因は、npmのglobal install先が書き込み不可のNix管理領域に寄っていること。

確認:

```bash
npm config get prefix
```

`/nix/store/...` やNix profile配下を指している場合、その場所にはnpmが書き込めない。

このリポジトリでは、`nodejs.nix` でnpm global install先をHOME配下に逃がす。

```text
~/.local/share/npm-global
```

確認:

```bash
type npm
echo "$NPM_GLOBAL_DIR"
npm config get prefix
```

期待値:

```text
npm is a function
/home/new_user/.local/share/npm-global
/home/new_user/.local/share/npm-global
```

この状態なら以下が使える。

```bash
npm install -g yarn
which yarn
yarn --version
```

ただし、`yarn` のような常用CLIは、できればNixで入れる。

### nvm使用時にnpm global prefixが混ざる

`~/.npmrc` に以下のようなprefixを直接書くと、nvm利用時のnpmにも影響することがある。

```ini
prefix=/home/new_user/.local/share/npm-global
```

そのため、このリポジトリでは `~/.npmrc` にprefixを直接書かない。

代わりに、`hm-extra.d/npm-global.bash` で `npm` 関数を定義し、nvm未使用時だけ `NPM_CONFIG_PREFIX` を付ける。

```bash
npm() {
  if [ -z "${NVM_BIN:-}" ]; then
    NPM_CONFIG_PREFIX="$NPM_GLOBAL_DIR" command npm "$@"
  else
    command npm "$@"
  fi
}
```

`NVM_BIN` がある場合は、nvm側のnpm挙動をそのまま使う。

### fcitx5系パッケージが衝突する

エラー例:

```text
pkgs.buildEnv error: two given paths contain a conflicting subpath:
  ...-fcitx5-with-addons.../bin/fcitx5
  ...-fcitx5.../bin/fcitx5
```

または:

```text
.../bin/fcitx5-config-qt
```

原因は、Home Managerの `i18n.inputMethod.fcitx5.addons` が `fcitx5-with-addons` を生成しているのに、`home.packages` に `fcitx5` や `fcitx5-configtool` を重複して入れていること。

`fcitx5.nix` では、addonは以下に寄せる。

```nix
i18n.inputMethod.fcitx5.addons = with pkgs; [
  fcitx5-mozc
  fcitx5-gtk
  qt6Packages.fcitx5-configtool
];
```

`home.packages` には重複して入れない。

### `fcitx5-configtool` が見つからない

現在のnixpkgsでは、`fcitx5-configtool` は以下に移動している。

```nix
qt6Packages.fcitx5-configtool
```

古い指定:

```nix
fcitx5-configtool
```

は以下のようなエラーになる。

```text
'fcitx5-configtool' has been renamed to/replaced by 'qt6Packages.fcitx5-configtool'
```

### `xorg.xprop` がdeprecated warningを出す

以下のwarningが出ることがある。

```text
evaluation warning: The xorg package set has been deprecated, 'xorg.xprop' has been renamed to 'xprop'
```

`xorg.xprop` ではなく、以下を使う。

```nix
xprop
```

### OCI configのpermission warning

OCI CLIで以下のような警告が出る場合。

```text
WARNING: Permissions on /home/.../.oci/config are too open.
```

確認:

```bash
ls -la ~/.oci/config
```

期待値:

```text
-rw------- ... ~/.oci/config
```

このリポジトリでは `home.file` のsymlinkではなく、activationで `install -m 600` している。

再適用:

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### SOPSがcreation rulesを見つけられない

エラー例:

```text
config file not found, or has no creation rules, and no keys provided through command line options
```

activationや補助コマンドの実行カレントディレクトリがrepoではない場合、SOPSが `.sops.yaml` を見つけられないことがある。

このリポジトリの補助コマンドでは、以下を明示する。

```bash
sops --config "$sops_config" --filename-override "$secrets_file"
```

### Home Manager switch時に既存ファイル衝突

既存ファイルがある場合は `-b backup` を付ける。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

これにより、衝突した既存ファイルは `.backup` として退避される。

### `home-manager switch -b backup` でattribute errorになる

このリポジトリでは、通常は以下を使う。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

誤って以下を実行すると、

```bash
home-manager switch -b backup
```

現在のログインユーザ名に対応する `homeConfigurations.<user>` が探され、存在せずにエラーになることがある。

例:

```text
error: flake 'git+file:///home/.../.config/home-manager' does not provide attribute
'homeConfigurations."actual_user".activationPackage'
```

これは設定が壊れたわけではない。
正しいコマンドで再実行する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### `home-manager news` がattribute errorになる

このリポジトリでは、flake attributeは `#default` を使う。

そのため、以下ではなく、

```bash
home-manager news
```

以下を使う。

```bash
home-manager news --flake "$HOME/.config/home-manager#default"
```

引数なしで実行すると、現在のログインユーザ名に対応するattributeを探しに行き、存在しない場合は以下のようなエラーになることがある。

```text
error: flake 'git+file:///home/.../.config/home-manager' does not provide attribute
'homeConfigurations."actual_user".config.news.json.output'
```

### `home-manager build` や `switch` が遅い

まず評価とbuildを切り分ける。

```bash
time nix eval --impure "$HOME/.config/home-manager#homeConfigurations.default.activationPackage.drvPath" --raw
time nix build --impure "$HOME/.config/home-manager#homeConfigurations.default.activationPackage" --no-link -L
time home-manager build --impure --flake "$HOME/.config/home-manager#default" -L
```

`nix build` が速く、`home-manager build` だけ遅い場合、Home Manager CLI側の後処理が原因のことがある。

未読newsが大量に溜まっている場合は、一度読む。

```bash
home-manager news --flake "$HOME/.config/home-manager#default"
```

### `Git tree is dirty` warning

以下はエラーではない。

```text
warning: Git tree '/home/.../.config/home-manager' is dirty
```

未commitの変更があるという意味。

確認:

```bash
git status --short
```

変更をcommitするか、不要な変更を戻すと消える。

### `result` symlinkができた

`home-manager build` を実行すると、カレントディレクトリに `result` symlinkができることがある。

これは一時的なビルド結果へのリンクなので、Git管理しない。

削除してよい。

```bash
rm -f result
```

`.gitignore` に以下を入れておく。

```gitignore
/result
/result-*
```

## ユーザ名依存の確認

機能ファイル側に実ユーザ名が直書きされていないか確認する。

```bash
cd ~/.config/home-manager

grep -RIn \
  --exclude-dir=.git \
  --exclude=flake.lock \
  --exclude=README.md \
  'actual_user\|/home/actual_user\|#actual_user' .
```

`actual_user` は確認したい実ユーザ名に置き換える。

`new_user` はプレースホルダとして以下に出る想定。

```text
flake.nix
local.example.nix
README.md
```

OCI configは `files/oci/config.template` の `@HOME_DIR@` から生成するため、`/home/new_user` のような固定パスは書かない。

```ini
key_file=@HOME_DIR@/.oci/sessions/DEFAULT/oci_api_key.pem
```

Vim secretは `files/vim/dotvimrc-secrets.template` 経由で `~/.vimrc-secrets` に生成するため、API keyの平文は書かない。

```vim
let $OPENAI_API_KEY = '@OPENAI_API_KEY@'
```

## 平文secretの確認

平文secretが残っていないか確認する。

```bash
find secrets -path '*/plain-*/*' -type f ! -name '.gitignore' -print
```

何も出ないのが理想。

API keyらしき文字列がGit管理対象に混ざっていないか確認する。

```bash
grep -RIn \
  --exclude-dir=.git \
  --exclude='*.yaml' \
  --exclude='*.sops.yaml' \
  'sk-[A-Za-z0-9_-]\{20,\}\|AGE-SECRET-KEY\|OPENAI_API_KEY=.*sk-' .
```

`files/vim/dotvimrc-secrets.template` には、秘密値ではなくplaceholderだけが残っていればよい。

```text
@OPENAI_API_KEY@
@ANTHROPIC_API_KEY@
@GEMINI_API_KEY@
```

