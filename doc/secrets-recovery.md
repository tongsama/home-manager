# Secret復元・復元テスト・Rollback・撤退

## Secret復元手順

新環境で秘密情報を復元する場合は、まずage秘密鍵を復元する。

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

その後、Home Managerを再適用する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

または手動deploy。

```bash
hm-ssh-secrets deploy
hm-oci-secrets deploy
hm-vim-secrets deploy
oke-kubeconfig
```

Vim用secretを新しく追加する場合:

```bash
cat > secrets/plain-vim/secrets.env <<'EOF'
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

## ユーザ作成からの復元テスト

このリポジトリの最終確認として、ユーザ削除・再作成からの復元を行う場合。

README内では対象ユーザ名を `new_user` と表記する。
実際の検証では、`new_user` を対象ユーザ名に読み替える。

別のsudo可能ユーザ、またはrootから実行する。

### 1. 対象ユーザを停止

```bash
sudo pkill -u new_user || true
```

### 2. 必要ならhomeを退避

```bash
sudo cp -a /home/new_user /home/new_user.before-delete
```

### 3. ユーザ削除

```bash
sudo deluser --remove-home new_user
```

### 4. ユーザ再作成

```bash
sudo adduser new_user
sudo usermod -aG sudo new_user
```

必要なら追加グループも設定する。

```bash
sudo usermod -aG docker new_user
```

### 5. ログイン

```bash
su - new_user
```

### 6. Flakes有効化

```bash
NIXCONF_DIR="$HOME/.config/nix"
mkdir -p "$NIXCONF_DIR"

cat > "$NIXCONF_DIR/nix.conf" <<'EOF'
experimental-features = nix-command flakes
EOF
```

### 7. 初回clone

初回構築時はSSH秘密鍵がまだないため、リポジトリを一時的にpublicへ変更してHTTPSでcloneする。

```bash
mkdir -p "$HOME/.config"

nix shell nixpkgs#git -c \
  git clone https://github.com/<owner>/<repo>.git "$HOME/.config/home-manager"
```

cloneが終わったら、すぐに`

### 7. 初回clone

初回構築時はSSH秘密鍵がまだないため、リポジトリを一時的にpublicへ変更してHTTPSでcloneする。

````bash
mkdir -p "$HOME/.config"

nix shell nixpkgs#git -c \
  git clone https://github.com/<owner>/<repo>.git "$HOME/.GitHub側でrepository visibilityをprivateへ戻す。

### 8. `local.nix` 作成

```bash
cd "$HOME/.config/home-manager"

cp local.example.nix local.nix
vi local.nix
````

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

WSL2 + WSLg環境の場合:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

### 9. age key配置

Home Manager初回適用前に、SOPSで使うage秘密鍵を配置する。

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

### 10. Vim用secretを配置する場合

必要に応じて、Home Manager初回適用前にVim用secretを置く。

```bash
mkdir -p secrets/plain-vim

cat > secrets/plain-vim/secrets.env <<'EOF'
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx
EOF

chmod 600 secrets/plain-vim/secrets.env
```

このファイルがある場合、初回 `home-manager switch` 中に自動で `secrets/vim.yaml` へ暗号化され、平文ファイルは削除される。

すでに `secrets/vim.yaml` がGitに存在する場合、この手順は不要。

### 11. Home Manager初回適用

```bash
nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### 12. Git remoteをSSHへ切り替え

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

### 13. 動作確認

```bash
echo "$STARSHIP_SHELL"
command -v starship
command -v vim
command -v gvim
command -v node
command -v npm
command -v kubectl
command -v helm
command -v oci

hm-ssh-secrets status
hm-oci-secrets status
hm-vim-secrets status

oci iam region list
kubectl config current-context
helm plugin list
```

Vim確認:

```bash
ls -la ~/.vimrc
vim +'echo exists("*plug#begin")' +qa
```

Node.js / npm確認:

```bash
node --version
npm --version
type npm
echo "$NPM_GLOBAL_DIR"
npm config get prefix
```

GUI / WSLg / fcitx5を有効にしている場合:

```bash
cat ~/.config/gtk-3.0/settings.ini 2>/dev/null || true
cat ~/.config/gtk-4.0/settings.ini 2>/dev/null || true

echo "$GTK_IM_MODULE"
echo "$QT_IM_MODULE"
echo "$XMODIFIERS"
echo "$GDK_BACKEND"
echo "$QT_QPA_PLATFORM"

pgrep -a fcitx5 || true
fcitx5-config-qt &
```

## Rollback

直前のHome Manager generationに戻す。

```bash
home-manager switch --rollback
```

世代一覧:

```bash
home-manager generations
```

特定世代をactivate:

```bash
/nix/store/xxxxxxxx-home-manager-generation/activate
```

これはHome Manager管理下の前世代に戻す操作。
Home Manager適用前のUbuntu素のhomeに完全復元する操作ではない。

## Home Manager撤退

完全撤退したい場合は、まず必要なファイルを退避する。

```bash
cp -a ~/.bashrc ~/.bashrc.before-hm-remove 2>/dev/null || true
cp -a ~/.profile ~/.profile.before-hm-remove 2>/dev/null || true
cp -a ~/.ssh ~/.ssh.before-hm-remove 2>/dev/null || true
cp -a ~/.oci ~/.oci.before-hm-remove 2>/dev/null || true
cp -a ~/.kube ~/.kube.before-hm-remove 2>/dev/null || true
cp -a ~/.vimrc ~/.vimrc.before-hm-remove 2>/dev/null || true
cp -a ~/.vim ~/.vim.before-hm-remove 2>/dev/null || true
cp -a ~/.config/fcitx5 ~/.config/fcitx5.before-hm-remove 2>/dev/null || true
cp -a ~/.local/share/npm-global ~/.local/share/npm-global.before-hm-remove 2>/dev/null || true
```

`.bashrc` からHome Manager管理ブロックだけを消す場合:

```bash
awk '
  $0 == "# >>> home-manager bash extras >>>" { in_block = 1; next }
  $0 == "# <<< home-manager bash extras <<<" { in_block = 0; next }
  !in_block { print }
' ~/.bashrc > ~/.bashrc.no-hm

mv ~/.bashrc ~/.bashrc.with-hm
mv ~/.bashrc.no-hm ~/.bashrc
```

