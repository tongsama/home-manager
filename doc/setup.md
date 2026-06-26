# セットアップ

## 前提

このリポジトリは、次の場所にcloneして使う前提。

```bash
~/.config/home-manager
```

README内では、対象ユーザ名をすべて `new_user` と表記する。

`new_user` は実ユーザ名ではなく、置き換え用のプレースホルダである。
実際の環境では、`new_user` を対象ユーザ名に読み替える。

## ユーザ名・home directory・systemについて

このリポジトリでは、環境ごとの差分をGit管理外の `local.nix` に書く。

```text
~/.config/home-manager/local.nix
```

`local.nix` には以下を書く。

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";
}
```

通常は以下のようにhome directoryが決まる。

```text
/home/new_user
```

特殊なhome directoryを使う場合は、`homeDirectory` を直接指定できる。

```nix
{
  username = "new_user";
  system = "x86_64-linux";
  homeDirectory = "/export/home/new_user";
}
```

`local.nix` はGit管理しない。

サンプルとして、Git管理される `local.example.nix` を置く。

```nix
{
  # Replace this with the target login user.
  username = "new_user";

  # Usually /home on Ubuntu.
  homePrefix = "/home";

  # Target system.
  # Examples:
  #   x86_64-linux
  #   aarch64-linux
  system = "x86_64-linux";

  # Optional.
  # If set, this wins over homePrefix + username.
  # homeDirectory = "/home/new_user";

  # GUI profile.
  # Available values:
  #   "none"
  #   "wslg-x11"
  #   "ubuntu-wayland"
  #   "ubuntu-x11"
  guiProfile = "none";

  # Enable fcitx5 + Mozc.
  fcitx5Enable = false;
}
```

初回clone後、以下で `local.nix` を作る。

```bash
cd "$HOME/.config/home-manager"

cp local.example.nix local.nix
vi local.nix
```

## `--impure` について

`local.nix` はGit管理外のファイルである。

Nix flakesは通常、pure evaluationで動くため、Git管理外の `local.nix` はそのままでは読まれない。
そのため、このリポジトリの通常運用では `--impure` を付ける。

標準コマンド:

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

初回実行:

```bash
nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

`--impure` を使わない運用も完全には捨てない。
`local.nix` を置かず、`flake.nix` 内の `defaultConfig` を直接編集すれば、pure evaluationでも動作する。

ただし、通常は `local.nix` + `--impure` を使う。

## 誤操作時の注意

このリポジトリでは、以下のように明示的に `#default` と `--impure` を付ける。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

`~/.config/home-manager` 配下で、誤って以下を実行しない。

```bash
home-manager switch -b backup
```

この場合、Home Managerが現在のログインユーザ名に対応するflake attributeを探しに行くことがある。

たとえば現在のログインユーザが `actual_user` の場合、内部的には以下のようなattributeを探す。

```text
homeConfigurations."actual_user".activationPackage
```

しかし、`local.nix` は `--impure` なしでは読み込まれない。
そのため、以下のような分かりにくいエラーになることがある。

```text
error: flake 'git+file:///home/.../.config/home-manager' does not provide attribute
'homeConfigurations."actual_user".activationPackage'
```

これは設定が壊れたわけではない。
正しいコマンドで再実行する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

`home-manager news` も同様に、flake attributeを明示する。

```bash
home-manager news --flake "$HOME/.config/home-manager#default"
```

`home-manager news` を引数なしで実行すると、現在のログインユーザ名に対応する `homeConfigurations.<user>` を探しに行き、存在しない場合はattribute errorになることがある。

## Home Manager newsについて

Home Managerの実行後、以下のような通知が出ることがある。

```text
未読のお知らせが371件あります。
"home-manager news"コマンドで確認できます。
```

このリポジトリでは `homeConfigurations.default` を使うため、news確認時も `#default` を明示する。

```bash
home-manager news --flake "$HOME/.config/home-manager#default"
```

未読newsが大量に溜まっていると、`home-manager build` や `home-manager switch` の後処理が遅くなることがある。
その場合、一度newsを読むと改善することがある。

```bash
home-manager news --flake "$HOME/.config/home-manager#default"
```

newsを完全に黙らせたい場合は、以下を設定できる。

```nix
news.display = "silent";
```

ただし、このリポジトリでは通常、newsが出たら読む運用とする。
そのため、標準では `news.display = "silent";` は設定しない。

## Nix install方針

Ubuntu上でユーザ作成から再現テストする場合は、multi-user Nixを推奨する。

multi-user Nixは `nix-daemon` を使い、`/nix` storeをシステム全体で共有する。
ユーザを削除して作り直しても、Nix storeが特定ユーザのhomeやUIDに依存しにくい。

### 推奨: multi-user install

Ubuntuなどsystemdが使える環境では、基本的にこちらを使う。

multi-user Nixは、通常、管理者ユーザでインストールする。

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

インストール後、ログインし直す。

確認:

```bash
nix --version
systemctl status nix-daemon
```

### 代替: single-user install

systemdがない環境や、一時的な検証ではsingle-user installでもよい。

single-user Nixは、**対象ユーザを作成して、そのユーザでログインした後に実行する**。

例:

```bash
sudo adduser new_user
sudo usermod -aG sudo new_user

su - new_user
```

対象ユーザでログインした状態で、single-user Nixをインストールする。

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

single-user installでは、Nix installerが対象ユーザの `~/.profile` にNix環境読み込み行を自動追加する。

例:

```bash
if [ -e /home/new_user/.nix-profile/etc/profile.d/nix.sh ]; then . /home/new_user/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
```

そのため、インストール後はログインし直すか、新しいログインシェルを開けば `nix` コマンドが使えるようになる。

確認:

```bash
nix --version
```

ただし、single-user installは `/nix` がそのユーザに寄るため、ユーザ削除・再作成テストとは相性がよくない。
ユーザ削除からの復元テストを繰り返す場合は、multi-user Nixの方が扱いやすい。

## Flakes有効化

ユーザごとに以下を設定する。

```bash
NIXCONF_DIR="$HOME/.config/nix"
mkdir -p "$NIXCONF_DIR"

cat > "$NIXCONF_DIR/nix.conf" <<'EOF'
experimental-features = nix-command flakes
EOF
```

## 初回セットアップ

### 1. ユーザ作成

例:

```bash
sudo adduser new_user
sudo usermod -aG sudo new_user
```

必要ならdockerグループなども追加する。

```bash
sudo usermod -aG docker new_user
```

ログイン:

```bash
su - new_user
```

### 2. Flakes有効化

```bash
NIXCONF_DIR="$HOME/.config/nix"
mkdir -p "$NIXCONF_DIR"

cat > "$NIXCONF_DIR/nix.conf" <<'EOF'
experimental-features = nix-command flakes
EOF
```

### 3. リポジトリを一時的にpublicへ変更

このリポジトリは基本private運用だが、初回構築時はSSH秘密鍵がまだ存在しない。

そのため、初回clone前にGitHub側で一時的にrepository visibilityをpublicへ変更する。

clone完了後は、すぐにprivateへ戻す。

### 4. リポジトリをclone

gitがまだない場合は、Nix経由でgitを一時実行する。

```bash
mkdir -p "$HOME/.config"

nix shell nixpkgs#git -c \
  git clone https://github.com/<owner>/<repo>.git "$HOME/.config/home-manager"
```

clone後、すぐにGitHub側でrepository visibilityをprivateへ戻す。

移動:

```bash
cd "$HOME/.config/home-manager"
```

### 5. `local.nix` を作成

```bash
cp local.example.nix local.nix
vi local.nix
```

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "none";
  fcitx5Enable = false;
}
```

WSL2 + WSLgでGUIアプリとfcitx5を使う場合:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

通常のUbuntu Waylandデスクトップでfcitx5を使う場合:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "ubuntu-wayland";
  fcitx5Enable = true;
}
```

`new_user` は実際の対象ユーザ名に変更する。

### 6. age keyを配置

Home Manager初回適用前に、SOPSで使うage秘密鍵を配置する。

この鍵があると、初回Home Manager適用時点でSSH秘密鍵、OCI API秘密鍵、Vim用API keyなどを復号・配置できる。

```bash
SOPSCONF_DIR="$HOME/.config/sops/age"
mkdir -p "$SOPSCONF_DIR"
chmod 700 -R "$SOPSCONF_DIR"

cat << 'EOF' > "$SOPSCONF_DIR/keys.txt"
# created: 2026-06-24T17:44:56+09:00
# public key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AGE-SECRET-KEY-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

chmod 600 "$SOPSCONF_DIR/keys.txt"
```

注意:

* `keys.txt` は絶対にGit管理しない
* `keys.txt` は別環境復元に必要
* `AGE-SECRET-KEY-...` は実際のage秘密鍵に置き換える
* `# public key:` は `.sops.yaml` に登録されている公開鍵と対応している必要がある

### 7. Vim用secretを配置する場合

Vim設定内でOpenAI API keyなどを使う場合は、Home Manager初回適用前に平文の一時ファイルを置く。

```bash
mkdir -p secrets/plain-vim

cat > secrets/plain-vim/secrets.env <<'EOF'
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx
GEMINI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

chmod 600 secrets/plain-vim/secrets.env
```

`secrets/plain-vim/secrets.env` が存在する場合、`home-manager switch` 時に自動で以下を行う。

```text
secrets/plain-vim/secrets.env
  -> secrets/vim.yaml へSOPS暗号化
  -> secrets/plain-vim/secrets.env を削除
  -> files/vim/dotvimrc-secrets.template と secrets/vim.yaml から ~/.vimrc-secrets を生成
```

`~/.vimrc` 本体は `files/vim/dotvimrc` への out-of-store symlink として配置され、
その場での編集はそのまま本リポジトリの変更となる (生成物ではない)。

すでに `secrets/vim.yaml` がGitに存在し、age keyで復号できる場合は、この手順は不要。

### 8. 初回Home Manager適用

Home Managerがまだ入っていない状態では、`nix run` で実行する。

```bash
nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

以後は `home-manager` コマンドが使える。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### 9. Git remoteをSSHへ切り替え

初回Home Manager適用後は、SSH秘密鍵が復号・配置されている。

以後のGit操作はSSH経由にする。

```bash
cd "$HOME/.config/home-manager"

git remote -v
git remote remove origin
git remote add origin git@github.com:<owner>/<repo>.git
git remote -v
```

SSH Host aliasを使う場合:

```bash
git remote remove origin
git remote add origin odgit:<owner>/<repo>.git
```

接続確認:

```bash
ssh -T git@github.com
```

## 通常の反映コマンド

```bash
cd "$HOME/.config/home-manager"

home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

`local.nix` を使う通常運用では、必ず `--impure` を付ける。

`secrets/plain-vim/secrets.env` が存在する場合は、このswitch中に自動で `secrets/vim.yaml` へ暗号化され、平文ファイルは削除される。

## 任意の場所にlocal configを置く

通常は以下を読む。

```text
~/.config/home-manager/local.nix
```

別の場所にlocal configを置きたい場合は、`HM_LOCAL_CONFIG` を使う。

```bash
HM_LOCAL_CONFIG="$HOME/.config/hm-local.nix" \
  home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

## よく使うコマンド

Home Manager反映:

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

初回Home Manager反映:

```bash
nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

Home Manager news確認:

```bash
home-manager news --flake "$HOME/.config/home-manager#default"
```

世代確認:

```bash
home-manager generations
```

rollback:

```bash
home-manager switch --rollback
```

SSH secrets確認:

```bash
hm-ssh-secrets status
```

SSH secrets復号配置:

```bash
hm-ssh-secrets deploy
```

OCI secrets確認:

```bash
hm-oci-secrets status
```

OCI secrets復号配置:

```bash
hm-oci-secrets deploy
```

Vim secrets確認:

```bash
hm-vim-secrets status
```

Vim secrets自動sync:

```bash
hm-vim-secrets sync-if-present
```

Vim secrets復号配置:

```bash
hm-vim-secrets deploy
```

Vim secrets編集:

```bash
hm-vim-secrets edit
```

OKE kubeconfig再生成:

```bash
oke-kubeconfig
```

OCI確認:

```bash
oci iam region list
```

Kubernetes確認:

```bash
kubectl config current-context
kubectl get nodes
```

Helm plugin確認:

```bash
helm plugin list
helm diff version
```

Starship確認:

```bash
echo "$STARSHIP_SHELL"
starship explain
```

Vim確認:

```bash
vim --version
gvim --version
vim +'echo exists("*plug#begin")' +qa
ls -la ~/.vimrc
```

Node.js / npm確認:

```bash
node --version
npm --version
type npm
echo "$NPM_GLOBAL_DIR"
npm config get prefix
```

フォント確認:

```bash
fc-list | grep -i bizin
fc-match "Bizin Gothic"
```

WSLg GTK設定確認:

```bash
cat ~/.config/gtk-3.0/settings.ini
cat ~/.config/gtk-4.0/settings.ini
```

fcitx5確認:

```bash
echo "$GTK_IM_MODULE"
echo "$QT_IM_MODULE"
echo "$XMODIFIERS"
pgrep -a fcitx5
fcitx5-config-qt &
```

