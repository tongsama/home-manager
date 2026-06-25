# Home Manager configuration

Ubuntu上で、Nix Home Managerを使ってユーザ環境を再現するための設定。

このリポジトリは、既存のUbuntu標準設定をできるだけ壊さずに、ユーザ環境を宣言的・半宣言的に管理する。

主な管理対象:

* Nix flake
* Home Manager
* Bash追加設定
* Starship prompt
* Vim / gVim
* vim-plug本体
* Vimプラグイン用の外部CLI
* ユーザ用フォント
* WSLg向けGTK設定
* fcitx5 + Mozc
* SSH config
* SSH秘密鍵のSOPS管理
* OCI CLI設定
* OCI API秘密鍵のSOPS管理
* OKE kubeconfig生成
* Kubernetes系CLI

  * kubectl
  * helm
  * helm diff plugin
  * helmfile
  * k9s

この構成は、通常のUbuntuだけでなく、WSL2上のUbuntuでも使うことを想定している。

WSL2 + WSLg環境では、GUIアプリ、ウィンドウ装飾、fcitx5の扱いが通常のUbuntuデスクトップ環境と異なる。
そのため、このリポジトリでは `local.nix` の `guiProfile` で環境差分を切り替える。

## 前提

このリポジトリは、次の場所にcloneして使う前提。

```bash
~/.config/home-manager
```

README内では、対象ユーザ名をすべて `new_user` と表記する。

`new_user` は実ユーザ名ではなく、置き換え用のプレースホルダである。
実際の環境では、`new_user` を対象ユーザ名に読み替える。

## リポジトリの公開範囲について

このリポジトリは基本的にprivateで運用する。

ただし、初回構築時はまだSSH秘密鍵が配置されていないため、private repositoryへSSH接続できない。
そのため、初回clone時だけ一時的にリポジトリをpublicへ変更し、HTTPSでcloneする。

cloneが終わったら、すぐにリポジトリをprivateへ戻す。

重要:

* publicにする時間は最小限にする
* 平文の秘密鍵を絶対にcommitしない
* `~/.config/sops/age/keys.txt` をcommitしない
* `local.nix` をcommitしない
* `secrets/plain-ssh/` の中身をcommitしない
* `secrets/plain-oci/` の中身をcommitしない
* GitHub上でprivateに戻したことを確認してから作業を続ける

初回clone例:

```bash
mkdir -p "$HOME/.config"

nix shell nixpkgs#git -c \
  git clone https://github.com/<owner>/<repo>.git "$HOME/.config/home-manager"
```

clone後、ただちにGitHub側でrepository visibilityをprivateへ戻す。

## 初回clone後のGit remote切り替え

初回cloneはHTTPSで行う。

Home Manager適用後、SSH秘密鍵が復号・配置されるため、それ以降はGit remoteをSSHに切り替える。

```bash
cd "$HOME/.config/home-manager"

git remote -v
git remote remove origin
git remote add origin git@github.com:<owner>/<repo>.git
git remote -v
```

接続確認:

```bash
ssh -T git@github.com
```

独自のSSH Host aliasを使っている場合は、remote URLもそれに合わせる。

例:

```bash
git remote remove origin
git remote add origin git@github.com:<owner>/<repo>.git
```

または、SSH configに `Host odgit` のようなaliasを定義している場合:

```bash
git remote remove origin
git remote add origin odgit:<owner>/<repo>.git
```

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

## GUI profileについて

このリポジトリでは、GUI環境の種類を `local.nix` の `guiProfile` で切り替える。

```nix
{
  guiProfile = "none";
}
```

利用できる値:

```text
none
wslg-x11
ubuntu-wayland
ubuntu-x11
```

### `none`

非GUI環境向け。

WSLg設定、fcitx5、GTK設定などを発火させない。

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

### `wslg-x11`

WSL2 + WSLg向け。

WSLgでは通常のGNOMEデスクトップセッションが存在しないため、GNOMEのdconf設定だけではウィンドウ装飾や入力メソッド設定が期待通りに反映されないことがある。

このプロファイルでは、以下を行う。

* GTK3 / GTK4用の `settings.ini` を生成する
* WSLg上のGTKアプリのウィンドウ装飾ボタンを調整する
* `/run/user/$UID/bus` がある場合、ユーザーD-Bus経由で `gsettings` を反映する
* fcitx5はWayland frontendを使わず、XWayland側に寄せる
* `GDK_BACKEND=x11`
* `QT_QPA_PLATFORM=xcb`
* fcitx5起動時に `--disable=wayland,waylandim` を付ける

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

### `ubuntu-wayland`

通常のUbuntuデスクトップ + Waylandセッション向け。

WSLg固有設定は使わない。
fcitx5はWayland frontendを使う。

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "ubuntu-wayland";
  fcitx5Enable = true;
}
```

### `ubuntu-x11`

通常のUbuntuデスクトップ + X11セッション向け。

WSLg固有設定は使わない。
fcitx5はX11向けの環境変数で動かす。

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "ubuntu-x11";
  fcitx5Enable = true;
}
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

## `Git tree is dirty` warningについて

Home Manager実行時に以下のwarningが出ることがある。

```text
warning: Git tree '/home/.../.config/home-manager' is dirty
```

これは、このGit repositoryに未commitの変更があるという意味。
エラーではない。

確認:

```bash
git status --short
```

変更内容をcommitするか、不要な変更を戻すとwarningは消える。

開発中やREADME修正中に出るのは普通。
ただし、復元手順の最終確認をするときは、できるだけcleanな状態にしておく。

```bash
git status --short
```

何も出なければclean。

## ディレクトリ構成

```text
~/.config/home-manager/
├── flake.nix
├── flake.lock
├── home.nix
├── bash.nix
├── ssh.nix
├── secrets-ssh.nix
├── oci.nix
├── secrets-oci.nix
├── k8s-tools.nix
├── k8s-oci.nix
├── starship.nix
├── vim.nix
├── fonts.nix
├── gui.nix
├── wslg.nix
├── fcitx5.nix
├── local.example.nix
├── local.nix                 # Git管理外
├── .sops.yaml
├── .gitignore
├── files/
│   ├── oci/
│   │   ├── config.template
│   │   └── sessions/DEFAULT/oci_api_key_public.pem
│   ├── starship/
│   │   └── starship.toml
│   └── vim/
│       └── vimrc
├── secrets/
│   ├── ssh.yaml
│   ├── oci.yaml
│   ├── plain-ssh/
│   │   └── .gitignore
│   └── plain-oci/
│       └── .gitignore
└── README.md
```

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

この鍵があると、初回Home Manager適用時点でSSH秘密鍵やOCI API秘密鍵を復号・配置できる。

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

### 7. 初回Home Manager適用

Home Managerがまだ入っていない状態では、`nix run` で実行する。

```bash
nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

以後は `home-manager` コマンドが使える。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### 8. Git remoteをSSHへ切り替え

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

## 設定ファイルの要点

### `flake.nix`

`flake.nix` の主な役割:

* `nixpkgs` と `home-manager` のバージョン固定
* `local.nix` の読み込み
* `username` / `homePrefix` / `homeDirectory` / `system` の決定
* `guiProfile` / `fcitx5Enable` の決定
* `homeConfigurations.default` の提供
* pure evaluation用のfallback値 `defaultConfig` の保持

通常運用では `local.nix` を `--impure` で読み込む。

```nix
defaultConfig = {
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "none";
  fcitx5Enable = false;
};
```

`local.nix` がある場合は、そちらが優先される。

```nix
{
  username = "actual_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

標準のflake attributeは以下。

```text
#default
```

そのため、通常コマンドは以下に統一する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

`extraSpecialArgs` では、`local.nix` から読み込んだローカル値を `home.nix` に渡す。

例:

```nix
extraSpecialArgs = {
  inherit username homeDirectory localConfigLoaded localConfigPathString;

  guiProfile = localConfig.guiProfile or "none";
  fcitx5Enable = localConfig.fcitx5Enable or false;
};
```

### `home.nix`

`home.nix` の主な役割:

* 各moduleのimport
* `home.username`
* `home.homeDirectory`
* `home.stateVersion`
* 基本パッケージ
* `programs.home-manager.enable = true`
* `local.nix` 読み込み忘れや、実行ユーザ不一致を検出するactivation guard
* `guiProfile` / `fcitx5Enable` を各module用のoptionへ渡す

読み込むmodule:

```nix
imports = [
  ./bash.nix
  ./ssh.nix
  ./secrets-ssh.nix
  ./oci.nix
  ./secrets-oci.nix
  ./k8s-tools.nix
  ./k8s-oci.nix
  ./starship.nix

  ./gui.nix
  ./fonts.nix
  ./vim.nix
  ./wslg.nix
  ./fcitx5.nix
];
```

ローカル設定値をmodule optionへ反映する。

```nix
my.gui.profile = guiProfile;
my.fcitx5.enable = fcitx5Enable;
```

`local.nix` が存在するのに `--impure` なしで実行された場合は、activation前に止める。

ただし、`home-manager switch -b backup` のようにflake attributeを明示しない場合、このガードに到達する前にattribute解決で失敗することがある。
その場合も、設定が壊れたわけではない。正しいコマンドで再実行する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### `gui.nix`

`gui.nix` はGUI環境の種別を表す共通optionを定義する。

```nix
options.my.gui.profile = lib.mkOption {
  type = lib.types.enum [
    "none"
    "wslg-x11"
    "ubuntu-wayland"
    "ubuntu-x11"
  ];

  default = "none";
};
```

この値をもとに、`wslg.nix` や `fcitx5.nix` が環境別に設定を切り替える。

### `wslg.nix`

`wslg.nix` は `my.gui.profile == "wslg-x11"` の場合だけ発火する。

主な役割:

* GTK3 / GTK4の `settings.ini` を生成する
* WSLg上のGTKアプリのタイトルバーに最小化・最大化ボタンを出す
* user D-Bus session busが存在する場合は、`gsettings` でも `button-layout` を設定する

生成されるファイル:

```text
~/.config/gtk-3.0/settings.ini
~/.config/gtk-4.0/settings.ini
```

内容:

```ini
[Settings]
gtk-decoration-layout=:minimize,maximize,close
```

`gsettings` 反映時は、`DBUS_SESSION_BUS_ADDRESS` があればそれを使う。
なければ `/run/user/$UID/bus` が存在する場合だけ使う。

`/run/user/$UID/at-spi/bus` はAT-SPI用のアクセシビリティバスであり、通常のGSettings用D-Bus session busではない。
そのため、このリポジトリでは `/run/user/$UID/bus` を見る。

確認:

```bash
cat ~/.config/gtk-3.0/settings.ini
cat ~/.config/gtk-4.0/settings.ini

ls -l /run/user/$(id -u)/bus
```

## Bash設定

Ubuntu標準の `~/.bashrc` と `~/.profile` はできるだけ維持する。

Home Managerでは `programs.bash.enable = true;` を使わない。
代わりに、追加設定を以下に生成する。

```bash
~/.config/bash/hm-extra.bash
```

`~/.bashrc` には、Home Managerのactivationで以下の管理ブロックだけを追加する。

```bash
# >>> home-manager bash extras >>>
# Home Manager bash extras
[ -r "$HOME/.config/bash/hm-extra.bash" ] && . "$HOME/.config/bash/hm-extra.bash"
# <<< home-manager bash extras <<<
```

これにより、Ubuntu標準 `.bashrc` を壊さずに、aliasやPATH追加、Starship init、fcitx5起動などを追加できる。

### `hm-extra.bash`

`hm-extra.bash` では、以下のような追加設定を行う。

```bash
path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_prepend "$HOME/Apps/bin"

alias g='git'
alias dc='docker compose'
alias lla='ls -la'
alias k9s='LANG=C k9s'
```

### `hm-extra.d`

moduleごとのBash追加処理は、以下のディレクトリに分割して置く。

```text
~/.config/bash/hm-extra.d/
```

`hm-extra.bash` は、このディレクトリ内の `*.bash` を読み込む。

```bash
if [ -d "$HOME/.config/bash/hm-extra.d" ]; then
  for f in "$HOME"/.config/bash/hm-extra.d/*.bash; do
    [ -r "$f" ] && . "$f"
  done
  unset f
fi
```

これにより、`bash.nix` にすべての追加処理を直接書かず、moduleごとにBash fragmentを分けられる。

例:

```text
~/.config/bash/hm-extra.d/fcitx5-wslg.bash
```

WSLg環境では、このfragmentからfcitx5を起動する。

### Starship init

`programs.bash.enable = true;` を使っていないため、Home ManagerのStarship bash integrationは使わない。

`hm-extra.bash` 側で、Nix store上のStarshipを絶対パスで呼び出す。

実際の設定では、`bash.nix` で `${pkgs.starship}/bin/starship` を埋め込む。

```bash
if [ -n "$BASH_VERSION" ] && [ -x "/nix/store/...-starship/bin/starship" ]; then
  eval "$("/nix/store/...-starship/bin/starship" init bash)"
fi
```

これにより、`su -` でログインシェルに入った場合でも、`.profile` でNix profileが読み込まれる前にStarshipを初期化できる。

確認:

```bash
su - new_user

echo "$STARSHIP_SHELL"
echo "$PROMPT_COMMAND"
```

期待値:

```text
bash
starship_precmd
```

## Starship設定

Starship本体はHome Managerで有効化する。

```nix
programs.starship = {
  enable = true;
  enableBashIntegration = false;
};

home.file.".config/starship.toml".source =
  ./files/starship/starship.toml;
```

設定ファイル:

```text
files/starship/starship.toml
```

配置先:

```text
~/.config/starship.toml
```

確認:

```bash
starship --version
starship explain
```

## Vim / gVim設定

Vim / gVimは `vim.nix` で管理する。

方針:

* Vim本体はHome Managerで導入する
* `~/.vimrc` はHome Managerで配置する
* vim-plug本体はHome Managerで配置する
* vim-plugで管理するVimプラグイン本体はHome Manager外で管理する
* Vimプラグインが要求する外部CLIはHome Managerで導入する

このリポジトリでは、Home Managerの `programs.vim` moduleは使わない。

理由:

* `programs.vim` を使うとHome Managerがcustomized Vimを生成する
* customized Vimは通常の `~/.vimrc` を読まないことがある
* vim-plug + `~/.vimrc` の通常運用と相性が悪い
* `programs.vim` がVim本体を入れるため、`home.packages` 側のVimと衝突しやすい

そのため、Vim本体は `home.packages` で入れ、設定ファイルは `home.file` で配置する。

### 管理ファイル

Vim設定ファイル:

```text
files/vim/vimrc
```

配置先:

```text
~/.vimrc
```

vim-plug本体:

```text
~/.vim/autoload/plug.vim
```

プラグイン配置先:

```text
~/.vim/plugged
```

`~/.vim/plugged` はvim-plugが管理する。
Git管理しない。

### 導入する外部CLI

Vimプラグイン用の外部CLIとして、以下をHome Managerで入れる。

* python3
* universal-ctags
* w3m
* fzf
* nodejs
* ripgrep

`nodejs` には通常 `npm` も含まれる。

Node.jsのバージョン管理は、必要に応じてnvm等を別途使う。
ただし、gvimをGUIから起動した場合や、nvm初期化前のshellから起動した場合でも最低限動くように、ベースの `nodejs` はNixで入れる。

### vim-plug

vim-plug本体はNixpkgsの `pkgs.vimPlugins.vim-plug` から取り出し、`~/.vim/autoload/plug.vim` に配置する。

Vimプラグイン本体は `.vimrc` の `Plug` 行で管理する。

例:

```vim
call plug#begin(expand('~/.vim/plugged'))

Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf.vim'

call plug#end()
```

プラグインのインストール:

```vim
:PlugInstall
```

更新:

```vim
:PlugUpdate
```

確認:

```bash
vim +'echo exists("*plug#begin")' +qa
```

期待値:

```text
1
```

## フォント設定

ユーザ用フォントは `fonts.nix` で管理する。

このリポジトリでは、GitHub Releasesで配布されているフォントzipをNixで取得し、Home Managerの `home.packages` に入れる。

主な用途:

* gVim
* terminal
* WSLg上のGUIアプリ
* Nerd Fonts対応フォント

Bizin Gothicなど、`yuru7` 氏のフォントを複数追加できるように、`fonts.nix` ではGitHub release assetをフォントパッケージ化する関数を使う。

例:

```nix
mkGithubReleaseFont {
  pname = "bizin-gothic-nf";
  repo = "bizin-gothic";
  tag = "v0.0.4";
  asset = "BizinGothicNF_v0.0.4.zip";
  hash = "sha256-...";
}
```

`hash` は初回追加時に `lib.fakeHash` を使い、Nixが表示する `got:` の値に差し替える。

初回例:

```nix
hash = lib.fakeHash;
```

`home-manager switch` 実行時に以下のようなエラーが出る。

```text
hash mismatch in fixed-output derivation
specified: sha256-...
got:       sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
```

`got:` の値を `hash` に貼り付ける。

```nix
hash = "sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=";
```

確認:

```bash
fc-list | grep -i bizin
fc-match "Bizin Gothic"
```

フォントを追加・更新した場合、必要に応じてキャッシュを更新する。

```bash
fc-cache -fv
```

## WSLg GUI設定

WSL2 + WSLgでは、通常のGNOME desktop sessionが存在しない。

そのため、GNOMEのdconf設定だけでは、GTKアプリのウィンドウ装飾やタイトルバーボタンが期待通りに変わらないことがある。

このリポジトリでは、`guiProfile = "wslg-x11";` の場合だけ、`wslg.nix` でWSLg向け設定を行う。

### GTK settings.ini

生成されるファイル:

```text
~/.config/gtk-3.0/settings.ini
~/.config/gtk-4.0/settings.ini
```

内容:

```ini
[Settings]
gtk-decoration-layout=:minimize,maximize,close
```

確認:

```bash
cat ~/.config/gtk-3.0/settings.ini
cat ~/.config/gtk-4.0/settings.ini
```

### gsettings反映

WSLg環境では、`gsettings` を使う場合でも通常のGNOMEセッションが無い。

そのため、以下の順でD-Bus session busを探す。

1. `DBUS_SESSION_BUS_ADDRESS` がある場合はそれを使う
2. `/run/user/$UID/bus` がsocketとして存在する場合はそれを使う
3. どちらも無ければskipする

確認:

```bash
echo "$DBUS_SESSION_BUS_ADDRESS"
ls -l /run/user/$(id -u)/bus
```

`/run/user/$UID/at-spi/bus` はAT-SPI用のアクセシビリティバスであり、通常のGSettings用D-Bus session busではない。

## fcitx5 / Mozc設定

日本語入力は `fcitx5.nix` で管理する。

有効化は `local.nix` で行う。

```nix
{
  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

または、通常のUbuntu Waylandデスクトップの場合:

```nix
{
  guiProfile = "ubuntu-wayland";
  fcitx5Enable = true;
}
```

非GUI環境では無効にする。

```nix
{
  guiProfile = "none";
  fcitx5Enable = false;
}
```

### 導入するもの

Home Managerの `i18n.inputMethod` moduleを使う。

```nix
i18n.inputMethod = {
  enable = true;
  type = "fcitx5";

  fcitx5 = {
    addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };
};
```

注意:

`i18n.inputMethod.fcitx5.addons` を使うと、Home Manager側で `fcitx5-with-addons` が生成される。

そのため、`home.packages` に以下を重複して入れない。

```nix
fcitx5
fcitx5-mozc
fcitx5-gtk
qt6Packages.fcitx5-configtool
fcitx5-with-addons
```

これらを重複して入れると、以下のような衝突が起きることがある。

```text
pkgs.buildEnv error: two given paths contain a conflicting subpath:
  ...-fcitx5-with-addons.../bin/fcitx5
  ...-fcitx5.../bin/fcitx5
```

または:

```text
.../bin/fcitx5-config-qt
```

`fcitx5-configtool` は現在のnixpkgsでは以下を使う。

```nix
qt6Packages.fcitx5-configtool
```

### 入力メソッド設定

`fcitx5.nix` では、Mozcを既定の入力メソッドとして設定する。

```nix
settings = {
  inputMethod = {
    GroupOrder = {
      "0" = "Default";
    };

    "Groups/0" = {
      Name = "Default";
      "Default Layout" = "us";
      DefaultIM = "mozc";
    };

    "Groups/0/Items/0" = {
      Name = "keyboard-us";
      Layout = "";
    };

    "Groups/0/Items/1" = {
      Name = "mozc";
      Layout = "";
    };
  };
};
```

確認:

```bash
cat ~/.config/fcitx5/profile
```

### WSLg + fcitx5

WSLgでは、fcitx5をWayland frontendで動かすと期待通りに動かないことがある。

そのため、`guiProfile = "wslg-x11";` の場合はXWayland側に寄せる。

設定される環境変数:

```bash
export INPUT_METHOD=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
```

fcitx5起動:

```bash
fcitx5 -d --disable=wayland,waylandim
```

この起動処理は、`~/.config/bash/hm-extra.d/fcitx5-wslg.bash` に生成される。

新しいbashを開くと、`DISPLAY` がある場合だけfcitx5を自動起動する。

確認:

```bash
echo "$GTK_IM_MODULE"
echo "$QT_IM_MODULE"
echo "$XMODIFIERS"
echo "$GDK_BACKEND"
echo "$QT_QPA_PLATFORM"

pgrep -a fcitx5
```

期待値例:

```text
fcitx
fcitx
@im=fcitx
x11
xcb
fcitx5 -d --disable=wayland,waylandim
```

手動起動:

```bash
fcitx5 -d --disable=wayland,waylandim
```

設定画面:

```bash
fcitx5-config-qt &
```

### 通常のUbuntu Wayland + fcitx5

`guiProfile = "ubuntu-wayland";` の場合はWaylandを優先する。

設定される環境変数:

```bash
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
GDK_BACKEND=wayland,x11
QT_QPA_PLATFORM=wayland;xcb
```

fcitx5はXDG autostartで起動する。

生成されるファイル:

```text
~/.config/autostart/fcitx5.desktop
```

### 通常のUbuntu X11 + fcitx5

`guiProfile = "ubuntu-x11";` の場合はX11向けに設定する。

```bash
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
GDK_BACKEND=x11
QT_QPA_PLATFORM=xcb
```

fcitx5はXDG autostartで起動する。

## SSH設定

SSH configはHome Managerで管理する。

```text
~/.ssh/config
```

`ssh.nix` では `config.home.homeDirectory` を使い、ローカルユーザ名に依存しないようにする。

例:

```nix
let
  homeDir = config.home.homeDirectory;
in
{
  home.file.".ssh/config".text = ''
    Host github.com
      HostName github.com
      User git
      IdentityFile ${homeDir}/.ssh/id_rsa_github_nopass
  '';
}
```

注意:

```sshconfig
User some_remote_user
```

のような記述は、接続先サーバ上のリモートユーザ名であり、ローカルユーザ名ではない。
必要がなければ変更しない。

## SSH秘密鍵管理

秘密鍵はGitに平文で入れない。

SSH秘密鍵はSOPS + ageで暗号化し、以下に保存する。

```text
secrets/ssh.yaml
```

平文投入用ディレクトリ:

```text
secrets/plain-ssh/
```

この中身はGit管理しない。

### age key

age秘密鍵は以下に置く。

```text
~/.config/sops/age/keys.txt
```

権限:

```bash
SOPSCONF_DIR="$HOME/.config/sops/age"
mkdir -p "$SOPSCONF_DIR"
chmod 700 -R "$SOPSCONF_DIR"
chmod 600 "$SOPSCONF_DIR/keys.txt"
```

この `keys.txt` はGit管理しない。
別環境復元には、このファイルのバックアップが必要。

### `.sops.yaml`

SOPS設定。

```yaml
keys:
  - &main_user age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *main_user
```

`main_user` はYAML anchor名。
ユーザ名とは関係ない。

### `hm-ssh-secrets`

Home Manager適用後、以下の補助コマンドが使える。

```bash
hm-ssh-secrets init
hm-ssh-secrets status
hm-ssh-secrets sync
hm-ssh-secrets sync --keep
hm-ssh-secrets add <key-name>
hm-ssh-secrets deploy
hm-ssh-secrets deploy --soft
hm-ssh-secrets edit
```

#### 初期化

```bash
hm-ssh-secrets init
```

#### 平文秘密鍵から暗号化

```bash
cp /path/to/id_rsa_github_nopass secrets/plain-ssh/id_rsa_github_nopass

hm-ssh-secrets sync
```

`sync` は `secrets/plain-ssh/` の秘密鍵を `secrets/ssh.yaml` に暗号化して取り込み、平文ファイルを削除する。

平文を残したい場合:

```bash
hm-ssh-secrets sync --keep
```

#### 標準入力から追加

```bash
hm-ssh-secrets add id_rsa_example
```

秘密鍵を貼り付け、最後に `Ctrl-D`。

#### 復号して配置

```bash
hm-ssh-secrets deploy
```

配置先:

```text
~/.ssh/<key-name>
```

秘密鍵は `0600` で配置される。

#### Home Manager switch時のsoft deploy

Home Manager activationでは `hm-ssh-secrets deploy --soft` を実行する。

`--soft` は、age keyや `secrets/ssh.yaml` がまだ無い場合でもHome Manager switchを止めない。
初回構築時にsecret復元前でも最低限の環境構築を進めるため。

## OCI設定

OCI CLIはHome Managerで導入する。

```nix
home.packages = with pkgs; [
  oci-cli
];
```

OCI configと公開鍵は `files/` から配置する。

```text
files/oci/config.template
files/oci/sessions/DEFAULT/oci_api_key_public.pem
```

OCI API秘密鍵はSOPSで管理する。

```text
secrets/oci.yaml
```

### OCI config template

`~/.oci/config` は直接Git管理しない。
代わりに以下のtemplateをGit管理する。

```text
files/oci/config.template
```

例:

```ini
[DEFAULT]
user=ocid1.user.oc1..xxxxxxxx
fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
tenancy=ocid1.tenancy.oc1..xxxxxxxx
region=ap-osaka-1
key_file=@HOME_DIR@/.oci/sessions/DEFAULT/oci_api_key.pem
```

Home Manager activation時に `@HOME_DIR@` が `config.home.homeDirectory` に置換され、以下に `0600` で配置される。

```text
~/.oci/config
```

例:

```ini
key_file=/home/new_user/.oci/sessions/DEFAULT/oci_api_key.pem
```

別ユーザ名にした場合は自動で変わる。

### OCI公開鍵

公開鍵は以下に置く。

```text
files/oci/sessions/DEFAULT/oci_api_key_public.pem
```

Home Manager activation時に以下へ配置される。

```text
~/.oci/sessions/DEFAULT/oci_api_key_public.pem
```

### OCI秘密鍵

平文投入用:

```text
secrets/plain-oci/oci_api_key.pem
```

暗号化後:

```text
secrets/oci.yaml
```

配置先:

```text
~/.oci/sessions/DEFAULT/oci_api_key.pem
```

秘密鍵は `0600` で配置される。

### `hm-oci-secrets`

Home Manager適用後、以下の補助コマンドが使える。

```bash
hm-oci-secrets init
hm-oci-secrets status
hm-oci-secrets sync
hm-oci-secrets sync --keep
hm-oci-secrets add
hm-oci-secrets deploy
hm-oci-secrets deploy --soft
hm-oci-secrets edit
```

#### 初期化

```bash
hm-oci-secrets init
```

#### 平文秘密鍵から暗号化

```bash
cp /path/to/oci_api_key.pem secrets/plain-oci/oci_api_key.pem

hm-oci-secrets sync
```

`sync` は `secrets/plain-oci/oci_api_key.pem` を `secrets/oci.yaml` に暗号化して取り込み、平文ファイルを削除する。

平文を残したい場合:

```bash
hm-oci-secrets sync --keep
```

#### 標準入力から追加

```bash
hm-oci-secrets add
```

秘密鍵を貼り付け、最後に `Ctrl-D`。

#### 復号して配置

```bash
hm-oci-secrets deploy
```

配置先:

```text
~/.oci/sessions/DEFAULT/oci_api_key.pem
```

#### Home Manager switch時のsoft deploy

Home Manager activationでは `hm-oci-secrets deploy --soft` を実行する。

`--soft` は、age keyや `secrets/oci.yaml` がまだ無い場合でもHome Manager switchを止めない。
初回構築時にsecret復元前でも最低限の環境構築を進めるため。

### OCI確認

```bash
oci iam region list
```

権限警告が出る場合は以下を確認する。

```bash
ls -la ~/.oci
ls -la ~/.oci/config
ls -la ~/.oci/sessions/DEFAULT
```

期待値:

```text
~/.oci                                  700
~/.oci/sessions                         700
~/.oci/sessions/DEFAULT                 700
~/.oci/config                           600
~/.oci/sessions/DEFAULT/oci_api_key.pem 600
```

## Kubernetes / OKE

Kubernetes共通ツールは `k8s-tools.nix` で管理する。

```nix
let
  helm = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [
      helm-diff
    ];
  };
in
{
  home.packages = with pkgs; [
    kubectl
    helm
    helmfile
    k9s
  ];
}
```

注意:

`pkgs.kubernetes-helm` とwrap済み `helm` の両方を `home.packages` に入れない。
`bin/helm` が衝突する可能性がある。

確認:

```bash
kubectl version --client
helm version
helm plugin list
helm diff version
helmfile --version
k9s version
```

### OKE kubeconfig

OKE kubeconfig生成は `k8s-oci.nix` で管理する。

設定ファイル:

```text
~/.config/oke/default.env
```

例:

```bash
OCI_CLI_PROFILE=DEFAULT
OCI_REGION=ap-osaka-1

OKE_CLUSTER_ID=ocid1.cluster.oc1.ap-osaka-1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OKE_KUBE_ENDPOINT=PUBLIC_ENDPOINT

# memo only
OKE_PUBLIC_ENDPOINT=xxx.xxx.xxx.xxx:6443

KUBECONFIG_PATH=$HOME/.kube/config
```

補助コマンド:

```bash
oke-kubeconfig
```

実行内容:

```bash
oci ce cluster create-kubeconfig \
  --cluster-id "$OKE_CLUSTER_ID" \
  --file "$KUBECONFIG_PATH" \
  --region "$OCI_REGION" \
  --token-version 2.0.0 \
  --kube-endpoint "$OKE_KUBE_ENDPOINT" \
  --overwrite
```

Home Manager activation時にも自動実行する。
ただしOCI認証やネットワークに依存するため、失敗してもHome Manager switch自体は止めない。

手動再実行:

```bash
oke-kubeconfig
```

確認:

```bash
kubectl config current-context
kubectl get nodes
```

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
oke-kubeconfig
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

cloneが終わったら、すぐにGitHub側でrepository visibilityをprivateへ戻す。

### 8. `local.nix` 作成

```bash
cd "$HOME/.config/home-manager"

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

### 10. Home Manager初回適用

```bash
nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### 11. Git remoteをSSHへ切り替え

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

### 12. 動作確認

```bash
echo "$STARSHIP_SHELL"
command -v starship
command -v vim
command -v gvim
command -v kubectl
command -v helm
command -v oci

hm-ssh-secrets status
hm-oci-secrets status

oci iam region list
kubectl config current-context
helm plugin list
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

WSLgでは、Wayland frontendではなくXWayland側へ寄せる。

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

## Git管理しないもの

`.gitignore` 例:

```gitignore
/result
/result-*

# local environment config
/local.nix
/local.*.nix
!/local.example.nix

# plaintext secrets
secrets/plain-ssh/*
!secrets/plain-ssh/.gitignore

secrets/plain-oci/*
!secrets/plain-oci/.gitignore

# vim-plug managed plugins
/.vim/plugged

# local secret keys
keys.txt
*.plain
*.dec
*.tmp
```

以下はGitに入れない。

```text
local.nix
~/.config/sops/age/keys.txt
secrets/plain-ssh/*
secrets/plain-oci/*
秘密鍵の平文
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

