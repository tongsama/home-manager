# Home Manager dotfiles

UbuntuなどのLinux環境で、Home Managerを使ってホームディレクトリ設定を復元するための設定リポジトリ。

この構成では、Ubuntu標準の `~/.bashrc` / `~/.profile` を丸ごとHome Manager管理にはしない。
代わりに、必要な追加設定だけを別ファイルとしてHome Managerで管理する。

また、SSH秘密鍵は平文でGit管理しない。
SOPS + ageで暗号化した `secrets/ssh.yaml` としてGit管理し、`home-manager switch` 時に復号して `~/.ssh/` に展開する。

`sops-nix` moduleは使わない。
systemdにも依存しない。
`home.activation` と `sops` CLIで復号・展開する。

---

## 前提

このflakeは再現性重視のため、ユーザ名とHOMEを固定している。

```nix
system = "x86_64-linux";
username = "kwatanabe-nix";
homeDirectory = "/home/${username}";
```

別ユーザ名で使う場合は、`flake.nix` の以下を変更する。

```nix
username = "kwatanabe-nix";
homeDirectory = "/home/${username}";
```

この設定の場合、Home Managerのflake attributeは以下になる。

```text
.#kwatanabe-nix
```

---

## 管理されるもの

### インストールされるパッケージ

`home.nix` の `home.packages` で以下を入れる。

```nix
home.packages = with pkgs; [
  git
  vim
  tmux
  sops
  age
];
```

### Home Manager自身

Home Managerコマンドも管理する。

```nix
programs.home-manager.enable = true;
```

初回だけは `nix run` でHome Managerをネット越しに直接実行する。
初回反映後は `home-manager` コマンドが使える。

### Bash追加設定

Ubuntu標準の `~/.bashrc` は丸ごと置き換えない。

Home Managerは以下の追加ファイルを生成する。

```text
~/.config/bash/hm-extra.bash
```

`~/.bashrc` には、Home Managerのactivation scriptによって以下の管理ブロックが追加される。

```bash
# >>> home-manager bash extras >>>
# Home Manager bash extras
[ -r "$HOME/.config/bash/hm-extra.bash" ] && . "$HOME/.config/bash/hm-extra.bash"
# <<< home-manager bash extras <<<
```

これにより、Ubuntu標準のbash設定を壊さずに、追加のPATHやaliasだけをHome Manager側で管理する。

### SSH config

`~/.ssh/config` をHome Managerで管理する。

SSH秘密鍵ファイルは `~/.ssh/id_rsa_*` などに配置され、`~/.ssh/config` から参照される。

### SSH秘密鍵

SSH秘密鍵はGitに平文で入れない。

暗号化済みファイルとして以下を管理する。

```text
secrets/ssh.yaml
```

復号用のage秘密鍵は以下に置く。

```text
~/.config/sops/age/keys.txt
```

このファイルは絶対にGit管理しない。
別環境で完全復元するには、このage秘密鍵のバックアップが必要。

---

## ディレクトリ構成

```text
~/.config/home-manager/
├── flake.nix
├── flake.lock
├── home.nix
├── bash.nix
├── ssh.nix
├── secrets-ssh.nix
├── .sops.yaml
├── .gitignore
├── secrets/
│   ├── ssh.yaml
│   └── plain-ssh/
│       └── .gitignore
└── README.md
```

---

## Git管理するもの

Git管理してよいもの。

```text
flake.nix
flake.lock
home.nix
bash.nix
ssh.nix
secrets-ssh.nix
.sops.yaml
.gitignore
secrets/ssh.yaml
secrets/plain-ssh/.gitignore
README.md
```

Git管理してはいけないもの。

```text
result
result-*
~/.config/sops/age/keys.txt
secrets/plain-ssh/*
~/.ssh/id_rsa_*
~/.ssh/dev-k8s_pullkey_for_ansible
```

`.gitignore` 例。

```gitignore
/result
/result-*

# plaintext secrets
secrets/plain-ssh/*
!secrets/plain-ssh/.gitignore

# local secret keys
keys.txt
*.plain
*.dec
*.tmp
```

`secrets/plain-ssh/.gitignore` は以下にする。

```gitignore
*
!.gitignore
```

---

# Nix / Home Manager が無い環境から復元する

NixやHome Managerがまだ入っていない素のUbuntu環境から復元する手順。

---

## 1. Nixをインストールする

single-user modeでNixをインストールする。

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

インストール後、現在のshellでNixを使えるようにする。

```bash
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
```

確認。

```bash
nix --version
```

---

## 2. flakesを有効化する

flakesを使うため、Nixのユーザ設定に書いておく。

```bash
NIXCONF_DIR="$HOME/.config/nix"
mkdir -p "$NIXCONF_DIR"

cat > "$NIXCONF_DIR/nix.conf" <<'EOF'
experimental-features = nix-command flakes
EOF
```

確認。

```bash
nix flake --help
```

---

## 3. このリポジトリを取得する

`git` がまだ無い場合でも、Nix経由で一時的にgitを使える。

```bash
mkdir -p "$HOME/.config"

nix shell nixpkgs#git -c git clone <this-repository-url> "$HOME/.config/home-manager"
cd "$HOME/.config/home-manager"
```

すでにgitがある環境なら普通にcloneしてよい。

```bash
mkdir -p "$HOME/.config"
git clone <this-repository-url> "$HOME/.config/home-manager"
cd "$HOME/.config/home-manager"
```

---

## 4. flakeのユーザ設定を確認する

`flake.nix` の以下が復元先ユーザと一致していることを確認する。

```nix
username = "kwatanabe-nix";
homeDirectory = "/home/${username}";
```

この設定の場合、Home Managerのflake attributeは以下。

```text
.#kwatanabe-nix
```

---

## 5. Home Managerをネット越しに直接実行する

まだ `home-manager` コマンドが無いので、最初は `nix run` でHome ManagerをGitHubから直接実行する。

```bash
nix run github:nix-community/home-manager/release-26.05 -- switch --flake .#kwatanabe-nix -b backup
```

このコマンドで以下を同時に行う。

* GitHub上のHome Managerを一時的に実行する
* このリポジトリのflakeを評価する
* `home.nix` を反映する
* `programs.home-manager.enable = true;` により、以後使う `home-manager` コマンドを導入する

もしflake attributeを現在のユーザ名に合わせている場合のみ、以下でもよい。

```bash
nix run github:nix-community/home-manager/release-26.05 -- switch --flake .#$USER -b backup
```

ただし、`$USER` と `homeConfigurations` の名前が一致していないと失敗する。
このリポジトリでは再現性重視のため、通常は以下のように明示する。

```bash
nix run github:nix-community/home-manager/release-26.05 -- switch --flake .#kwatanabe-nix -b backup
```

---

## 6. 以後はhome-managerコマンドを使う

初回switch後は `home-manager` コマンドが入っているので、次回以降はこれで反映できる。

```bash
home-manager switch --flake "$HOME/.config/home-manager#kwatanabe-nix" -b backup
```

リポジトリ内にいる場合はこれでもよい。

```bash
cd "$HOME/.config/home-manager"
home-manager switch --flake .#kwatanabe-nix -b backup
```

---

# SSH秘密鍵の復元

この構成では、SSH秘密鍵はSOPS + ageで暗号化した `secrets/ssh.yaml` としてGit管理する。

復号用のage秘密鍵は以下に置く。

```text
~/.config/sops/age/keys.txt
```

このファイルはGit管理しない。
別環境で完全復元するには、このage秘密鍵のバックアップが必要。

---

## パターン1: age秘密鍵のバックアップがある場合

これが一番きれいな復元方法。

まず、復号用age鍵を配置する。

```bash
mkdir -p "$HOME/.config/sops/age"
chmod 700 "$HOME/.config/sops" "$HOME/.config/sops/age"

cp /path/to/backup/keys.txt "$HOME/.config/sops/age/keys.txt"
chmod 600 "$HOME/.config/sops/age/keys.txt"
```

その後、Home Managerを反映する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#kwatanabe-nix" -b backup
```

これで `secrets/ssh.yaml` が復号され、SSH秘密鍵が `~/.ssh/` に展開される。

確認。

```bash
ls -la "$HOME/.ssh"
hm-ssh-secrets status
```

SSH接続テスト。

```bash
ssh -T git@github.com
ssh -T odgit
ssh -T git@hf.co
```

---

## パターン2: age秘密鍵はないが、SSH秘密鍵の平文バックアップがある場合

新しい環境としてage鍵を作り直す。

```bash
hm-ssh-secrets init
```

既存のSSH秘密鍵を追加する。

```bash
cp /path/to/private-keys/id_rsa_* "$HOME/.config/home-manager/secrets/plain-ssh/"
hm-ssh-secrets sync
```

その後、Home Managerを再適用する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#kwatanabe-nix" -b backup
```

---

## パターン3: age秘密鍵もSSH秘密鍵バックアップもない場合

復元できない。

`secrets/ssh.yaml` は暗号化されているため、復号用のage秘密鍵がなければ中身を取り出せない。

必ず以下を安全な場所にバックアップしておく。

```text
~/.config/sops/age/keys.txt
```

---

# SSH秘密鍵を追加する

## 方法A: ファイルを置いてsyncする

秘密鍵ファイルを `secrets/plain-ssh/` に置く。

```bash
cp "$HOME/.ssh/id_rsa_github_nopass" "$HOME/.config/home-manager/secrets/plain-ssh/"
cp "$HOME/.ssh/id_rsa_github_od_nopass" "$HOME/.config/home-manager/secrets/plain-ssh/"
```

暗号化ファイルを更新する。

```bash
hm-ssh-secrets sync
```

`sync` 後、`secrets/plain-ssh/` に置いた平文ファイルは削除される。

平文ファイルを残したい場合のみ、以下を使う。

```bash
hm-ssh-secrets sync --keep
```

通常は `--keep` は使わない。

---

## 方法B: 対話入力で追加する

```bash
hm-ssh-secrets add id_rsa_new
```

秘密鍵の中身を貼り付けて、最後に `Ctrl-D` を押す。

その場で `secrets/ssh.yaml` が更新される。

---

# SSH秘密鍵を展開する

通常は `home-manager switch` 時に自動で展開される。

```bash
home-manager switch --flake "$HOME/.config/home-manager#kwatanabe-nix" -b backup
```

手動で展開したい場合は以下を実行する。

```bash
hm-ssh-secrets deploy
```

状態確認。

```bash
hm-ssh-secrets status
```

---

# `hm-ssh-secrets` コマンド

## 初期化

```bash
hm-ssh-secrets init
```

以下を作成する。

```text
~/.config/sops/age/keys.txt
~/.config/home-manager/.sops.yaml
~/.config/home-manager/secrets/plain-ssh/.gitignore
```

`~/.config/sops/age/keys.txt` は復号用の秘密鍵。
絶対にGitに入れない。

---

## 状態確認

```bash
hm-ssh-secrets status
```

以下を確認できる。

* repo path
* age keyの有無
* `.sops.yaml` の有無
* `secrets/ssh.yaml` の有無
* 復号できるか
* `secrets/plain-ssh/` に未取り込みの平文ファイルがあるか

---

## 暗号化ファイル更新

```bash
hm-ssh-secrets sync
```

`secrets/plain-ssh/` にある秘密鍵ファイルを `secrets/ssh.yaml` に取り込み、暗号化する。

---

## 対話追加

```bash
hm-ssh-secrets add <key-name>
```

例。

```bash
hm-ssh-secrets add id_rsa_github_new
```

秘密鍵を標準入力から読み取り、暗号化して取り込む。

---

## 手動展開

```bash
hm-ssh-secrets deploy
```

`secrets/ssh.yaml` を復号して `~/.ssh/` に展開する。

---

## 暗号化ファイルを直接編集

```bash
hm-ssh-secrets edit
```

SOPSで `secrets/ssh.yaml` を直接編集する。

---

# 最短復元手順

Nix未導入の新規Ubuntu環境での最短手順。

```bash
# 1. Nix install
sh <(curl -L https://nixos.org/nix/install) --no-daemon
. "$HOME/.nix-profile/etc/profile.d/nix.sh"

# 2. flakes enable
NIXCONF_DIR="$HOME/.config/nix"
mkdir -p "$NIXCONF_DIR"

cat > "$NIXCONF_DIR/nix.conf" <<'EOF'
experimental-features = nix-command flakes
EOF

# 3. clone dotfiles
mkdir -p "$HOME/.config"
nix shell nixpkgs#git -c git clone <this-repository-url> "$HOME/.config/home-manager"
cd "$HOME/.config/home-manager"

# 4. first Home Manager switch
nix run github:nix-community/home-manager/release-26.05 -- switch --flake .#kwatanabe-nix -b backup

# 5. restore age key if available
mkdir -p "$HOME/.config/sops/age"
chmod 700 "$HOME/.config/sops" "$HOME/.config/sops/age"
cp /path/to/backup/keys.txt "$HOME/.config/sops/age/keys.txt"
chmod 600 "$HOME/.config/sops/age/keys.txt"

# 6. apply again to deploy SSH private keys
home-manager switch --flake "$HOME/.config/home-manager#kwatanabe-nix" -b backup
```

もし `homeConfigurations` 名を現在のユーザ名と一致させている場合は、以下のように `$USER` を使える。

```bash
nix run github:nix-community/home-manager/release-26.05 -- switch --flake .#$USER -b backup
```

ただし、このリポジトリは再現性重視のため、通常は明示的に `.#kwatanabe-nix` を指定する。

---

# よく使うコマンド

```bash
# Home Managerを適用
home-manager switch --flake "$HOME/.config/home-manager#kwatanabe-nix" -b backup

# リポジトリ内から適用
cd "$HOME/.config/home-manager"
home-manager switch --flake .#kwatanabe-nix -b backup

# SSH secrets状態確認
hm-ssh-secrets status

# SSH秘密鍵を追加
cp "$HOME/.ssh/id_rsa_new" "$HOME/.config/home-manager/secrets/plain-ssh/"
hm-ssh-secrets sync

# SSH秘密鍵を対話追加
hm-ssh-secrets add id_rsa_new

# SSH秘密鍵を手動展開
hm-ssh-secrets deploy

# 暗号化ファイルを直接編集
hm-ssh-secrets edit

# flake inputs更新
cd "$HOME/.config/home-manager"
nix flake update
home-manager switch --flake .#kwatanabe-nix -b backup
```

---

# トラブルシュート

## `age key not found` と表示される

復号用age鍵がない。

既存環境から復元する場合は、バックアップしておいた以下を配置する。

```text
~/.config/sops/age/keys.txt
```

配置コマンド。

```bash
mkdir -p "$HOME/.config/sops/age"
chmod 700 "$HOME/.config/sops" "$HOME/.config/sops/age"

cp /path/to/backup/keys.txt "$HOME/.config/sops/age/keys.txt"
chmod 600 "$HOME/.config/sops/age/keys.txt"
```

新規環境として作り直す場合は以下。

```bash
hm-ssh-secrets init
```

---

## `secrets/ssh.yaml` がないと言われる

まだSSH秘密鍵が暗号化管理されていない。

```bash
hm-ssh-secrets init
cp "$HOME/.ssh/id_rsa_xxx" "$HOME/.config/home-manager/secrets/plain-ssh/"
hm-ssh-secrets sync
```

---

## GitHub SSH接続が失敗する

SSH configを確認する。

```bash
cat "$HOME/.ssh/config"
```

秘密鍵が展開されているか確認する。

```bash
ls -la "$HOME/.ssh"
```

権限を確認する。

```bash
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh"/id_rsa_*
```

接続テスト。

```bash
ssh -T git@github.com
```

OpenDoor用aliasの接続テスト。

```bash
ssh -T odgit
```

Hugging Faceの接続テスト。

```bash
ssh -T git@hf.co
```

---

## `home-manager` コマンドがない

初回は `nix run` でHome Managerを直接実行する。

```bash
cd "$HOME/.config/home-manager"
nix run github:nix-community/home-manager/release-26.05 -- switch --flake .#kwatanabe-nix -b backup
```

初回適用後は、`programs.home-manager.enable = true;` により `home-manager` コマンドが使えるようになる。

---

## `nix flake` が使えない

flakesが有効化されていない可能性がある。

```bash
NIXCONF_DIR="$HOME/.config/nix"
mkdir -p "$NIXCONF_DIR"

cat > "$NIXCONF_DIR/nix.conf" <<'EOF'
experimental-features = nix-command flakes
EOF
```

その後、新しいshellを開くか、Nixのprofileを読み直す。

```bash
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
```

確認。

```bash
nix flake --help
```

---

## Home Managerのビルド結果 `result` ができる

`home-manager build` を実行すると、カレントディレクトリに `result` というsymlinkが作られることがある。

これはGit管理不要。

削除してよい。

```bash
rm result
```

`.gitignore` に入れておく。

```gitignore
/result
/result-*
```

---

# 注意

SSH秘密鍵やage秘密鍵は、平文でGitに入れない。

特に以下は絶対にcommitしない。

```text
~/.config/sops/age/keys.txt
~/.ssh/id_rsa_*
~/.config/home-manager/secrets/plain-ssh/*
```

`secrets/ssh.yaml` は暗号化済みなのでGit管理してよい。

ただし、復号用の `~/.config/sops/age/keys.txt` を失うと、既存の `secrets/ssh.yaml` は復号できない。
このage秘密鍵は必ず安全な場所にバックアップしておく。

