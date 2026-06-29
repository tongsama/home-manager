# ディレクトリ構成と設定ファイル

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
├── secrets-vim.nix
├── skkdict.nix
├── nvim.nix
├── nodejs.nix
├── fonts.nix
├── gui.nix
├── wslg.nix
├── fcitx5.nix
├── goenv.nix              # optional (既定 false)
├── pyenv.nix              # optional (既定 false)
├── rustup.nix             # optional (既定 false)
├── nodenv.nix             # optional (既定 false)
├── plenv.nix              # optional (既定 false)
├── local.example.nix
├── local.nix                 # Git管理外
├── .sops.yaml
├── .gitignore
├── files/
│   ├── bash/                     # hm-extra.d 用シェルfragment
│   │   ├── goenv.bash
│   │   ├── pyenv.bash
│   │   ├── rustup.bash
│   │   ├── nodenv.bash
│   │   └── plenv.bash
│   ├── oci/
│   │   ├── config.template
│   │   └── sessions/DEFAULT/oci_api_key_public.pem
│   ├── starship/
│   │   └── starship.toml
│   ├── vim/
│   │   ├── dotvimrc
│   │   ├── dotvimrc-secrets.template
│   │   ├── coc-settings.json
│   │   └── sonic-template/        # sonictemplate ユーザテンプレート
│   │       ├── _/                 # 任意 filetype 共通
│   │       ├── c/
│   │       ├── clang-format/
│   │       ├── rust/
│   │       └── sh/
│   ├── nvim/
│   │   └── init.vim
│   └── skkdict/
│       └── SKK-JISYO.MY.LL.eucjp.gz
├── secrets/
│   ├── ssh.yaml
│   ├── oci.yaml
│   ├── vim.yaml
│   ├── plain-ssh/
│   │   └── .gitignore
│   ├── plain-oci/
│   │   └── .gitignore
│   └── plain-vim/
│       └── .gitignore
├── doc/                      # 項目別ドキュメント
└── README.md                 # 概要・目次
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
* `modules`(local.nix) に応じて optional module の import を組み替える

読み込むmodule (core は常時、optional は `modules` で切り替え):

```nix
imports =
  [
    # --- core (常時有効) ---
    ./bash.nix
    ./ssh.nix
    ./secrets-ssh.nix
    ./starship.nix
    ./gui.nix
    ./wslg.nix
    ./fcitx5.nix
    ./vim.nix
    ./secrets-vim.nix
    ./skkdict.nix
  ]
  # --- optional (local.nix の modules で組み替え) ---
  ++ lib.optional  m.nvim ./nvim.nix
  ++ lib.optional  m.nodejs ./nodejs.nix
  ++ lib.optionals m.oci [ ./oci.nix ./secrets-oci.nix ]
  ++ lib.optionals m.kubernetes [ ./k8s-tools.nix ./k8s-oci.nix ]
  ++ lib.optional  m.fonts ./fonts.nix;
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

### モジュール構成の組み替え (`modules`)

「追加パッケージ群」(optional module) は `local.nix` の `modules` で有効/無効を切り替えられる。

```nix
# local.nix
modules = {
  oci = false;          # 既定 true のものを外す (bool)
  pyenv = "nix";        # version manager は false/true/"clone"/"nix" で source も選べる
  nodenv = "clone";
};
```

* 既定値は `flake.nix` の `moduleConfig`（と `home.nix` の `m`）で定義。指定しないキーは既定値のまま。
* `false` にすると、その module の import 自体が外れる（評価もされない）。
* 通常の optional module は bool (`true`/`false`)。
* **version manager** は `false` / `true`(既定source) / `"clone"` / `"nix"` を取り、source を選べる。
* `flake.nix` が既定値と `local.nix` の `modules` をマージし、`extraSpecialArgs.modules`
  として渡す。`home.nix` が `lib.optional` で import を組み立て、各 module が source を解釈する。

切り替え対象 (optional)。bool 列が通常モジュール、source 列が version manager:

| key | 既定 | 含まれる module / 本体 |
|---|---|---|
| `nvim` | true | `nvim.nix` |
| `nodejs` | true | `nodejs.nix` |
| `oci` | true | `oci.nix` + `secrets-oci.nix` |
| `kubernetes` | true | `k8s-tools.nix` + `k8s-oci.nix` |
| `fonts` | true | `fonts.nix` |

version manager (値 `false`/`true`/`"clone"`/`"nix"`、既定はいずれも無効):

| key | 既定 source | nix | clone | 備考 |
|---|---|---|---|---|
| `rustup` | `nix` | ✓ | ✗ | clone 非対応 (公式は curl インストーラ) |
| `pyenv` | `clone` | ✓ | ✓ | clone は `~/.pyenv` (python-build 同梱) |
| `goenv` | `clone` | ✗ | ✓ | nixpkgs に無い。clone は `~/.goenv` |
| `nodenv` | `clone` | (要確認) | ✓ | clone は `~/.nodenv` + node-build |
| `plenv` | `clone` | (要確認) | ✓ | clone は `~/.plenv` + perl-build |

* `"nix"` はそのツールが nixpkgs にある場合のみ。無いのに指定すると **明示エラー**
  (`undefined variable` ではなく「nixpkgs に見つかりません」と出る)。`pkgs ? <tool>` で判定。
* `"clone"` は各 module の activation が未取得時に `~/.X` へ `git clone --depth 1` する
  (バージョン更新は手動: `git -C ~/.X pull`)。オフライン等で失敗しても switch は止めず警告のみ。
* clone を既定にしているのは、同梱の `*-build` プラグイン (python-build / node-build 等、
  インストール可能なバージョン定義) を `git pull` で最新化できるため。
* シェル統合 (`files/bash/<tool>.bash` → `hm-extra.d/`) は clone/nix どちらでも動くようにしてある。
* なお `pyenv install` での stdlib ビルドには別途 dev ライブラリが必要
  (libssl-dev / zlib1g-dev / libbz2-dev / libreadline-dev / libsqlite3-dev /
  libffi-dev / liblzma-dev 等)。これは導入方法に関わらず必要。

core (常時有効・切り替え対象外): `bash` / `ssh`(+`secrets-ssh`) / `starship` /
`gui` / `wslg` / `fcitx5` / `vim`(+`secrets-vim` / `skkdict`)。

> 補足: `gui` / `wslg` / `fcitx5` は `my.gui.profile` 等で内部的に挙動が変わるため core 扱い。
> `vim` は主エディタかつ `nvim` の依存元 (init.vim が `~/.vimrc` を source) のため core。
> `kubernetes`(OKE) は実行時にOCI認証を使うため、実質 `oci` と併用が前提。

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

