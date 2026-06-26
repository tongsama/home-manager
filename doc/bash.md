# Bash / Starship 設定

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

これにより、Ubuntu標準 `.bashrc` を壊さずに、aliasやPATH追加、Starship init、npm global用PATH追加、fcitx5起動などを追加できる。

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
~/.config/bash/hm-extra.d/npm-global.bash
~/.config/bash/hm-extra.d/fcitx5-wslg.bash
~/.config/bash/hm-extra.d/tty.bash
```

WSLg環境では、`fcitx5-wslg.bash` からfcitx5を起動する。

Node.js/npm環境では、`npm-global.bash` からnpm global install用のPATH追加とnpm wrapperを読み込む。

### `tty.bash` (端末設定)

`bash.nix` が配置する端末設定 fragment。XON/XOFF フロー制御を無効化し、
`<C-q>` / `<C-s>` が端末（フロー制御）に奪われず、Vim等のアプリへ届くようにする。

```bash
if [[ $- == *i* ]] && [ -t 0 ]; then
  stty -ixon 2>/dev/null || true
fi
```

対話シェルかつ stdin が端末のときだけ `stty` を実行する。
非対話シェルや tty が無い環境（scp等）での `Inappropriate ioctl for device` エラーを避けるため。

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

### `NIX_HM_GOOGLEDRIVE_DIR` (Google Drive連携)

Google Driveのマウント先を、後続のスクリプトやVim設定から参照できるようにするための環境変数。
`hm-extra.bash` の中で、ランタイムにディレクトリの有無を判定して設定する。

設定値は `local.nix` の `googleDriveDir`（省略時の既定は `~/Gdrive_kwatan`）。
`flake.nix` の `extraSpecialArgs` 経由で `bash.nix` に渡される。

```nix
# local.nix
googleDriveDir = "~/Gdrive_kwatan";  # "" にすると連携を無効化
```

`hm-extra.bash` での挙動:

* `googleDriveDir` が空文字でない
* かつ、`~` を展開した実体ディレクトリが存在する
* かつ、その中にファイル/ディレクトリが1つ以上ある

の **すべてを満たすときだけ**、`googleDriveDir` に**指定された値そのまま**（`~` 未展開のまま）を
`NIX_HM_GOOGLEDRIVE_DIR` に `export` する。満たさない場合は環境変数自体を設定しない。

```bash
echo "${NIX_HM_GOOGLEDRIVE_DIR:-<unset>}"
# => ~/Gdrive_kwatan   (Google Driveがマウント済みで中身がある場合)
# => <unset>           (未マウント / 空 / googleDriveDir="" の場合)
```

注意:

* 値は `~` を含む未展開文字列なので、消費側で展開が必要
  （例: `eval echo "$NIX_HM_GOOGLEDRIVE_DIR"` や `"${NIX_HM_GOOGLEDRIVE_DIR/#\~/$HOME}"`）。
* 現状この変数を読む利用側はまだ無く、後続作業のための足場として用意している。

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

