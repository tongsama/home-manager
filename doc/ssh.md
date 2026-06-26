# SSH 設定 / SSH秘密鍵管理

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

