# OCI 設定

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

秘密を削除する。

平文を残したい場合:

```bash
hm-oci-secrets sync --keep
```

#### 標準入力鍵を貼り付け、最後に `Ctrl-D`。

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

