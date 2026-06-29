# Vim / gVim 設定

## Vim / gVim設定

Vim / gVimは `vim.nix` と `secrets-vim.nix` で管理する。

方針:

* Vim本体はHome Managerで導入する
* `~/.vimrc` 本体 (`files/vim/dotvimrc`) はGit管理し、out-of-store symlinkで配置する
* secretは `~/.vimrc-secrets` に分離し、`files/vim/dotvimrc-secrets.template` と `secrets/vim.yaml` から生成して `~/.vimrc` から source する
* vim-plug本体はHome Managerで配置する
* vim-plugで管理するVimプラグイン本体はHome Manager外で管理する
* Vimプラグインが要求する外部CLIはHome Managerで導入する

このリポジトリでは、Home Managerの `programs.vim` moduleは使わない。

理由:

* `programs.vim` を使うとHome Managerがcustomized Vimを生成する
* customized Vimは通常の `~/.vimrc` を読まないことがある
* vim-plug + `~/.vimrc` の通常運用と相性が悪い
* `programs.vim` がVim本体を入れるため、`home.packages` 側のVimと衝突しやすい

そのため、Vim本体は `home.packages` で入れ、`~/.vimrc` 本体は out-of-store symlink で配置する。
secretのみ activation で `~/.vimrc-secrets` として生成する。

### 管理ファイル

Vim本体 (out-of-store symlink元、Git管理):

```text
files/vim/dotvimrc
```

symlink先:

```text
~/.vimrc
```

Vim secret template:

```text
files/vim/dotvimrc-secrets.template
```

secret生成先 (`~/.vimrc` から source):

```text
~/.vimrc-secrets
```

Vim secret:

```text
secrets/vim.yaml
```

平文投入用:

```text
secrets/plain-vim/secrets.env
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

### Vim secret template

`files/vim/dotvimrc-secrets.template` には、API keyなどの秘密値を直接書かない。

代わりに、以下のようなplaceholderを書き、`~/.vimrc-secrets` 生成時にsopsの値で置換する。
`files/vim/dotvimrc` 側ではこの変数を source して参照する。

```vim
let $OPENAI_API_KEY = '@OPENAI_API_KEY@'
let $ANTHROPIC_API_KEY = '@ANTHROPIC_API_KEY@'
let $GEMINI_API_KEY = '@GEMINI_API_KEY@'
```

または、Vim pluginが `g:` 変数を見る場合:

```vim
let g:openai_api_key = '@OPENAI_API_KEY@'
let g:anthropic_api_key = '@ANTHROPIC_API_KEY@'
```

`secrets/vim.yaml` に対応するkeyが存在する場合、activation時に `@KEY@` が秘密値へ置換される。

### Vim secrets.env

平文で一時投入する場合は、以下を作る。

```text
secrets/plain-vim/secrets.env
```

例:

```bash
mkdir -p secrets/plain-vim

cat > secrets/plain-vim/secrets.env <<'EOF'
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx
GEMINI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

chmod 600 secrets/plain-vim/secrets.env
```

`secrets.env` は `KEY=VALUE` 形式で書く。

以下も許可する。

```bash
export OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
OPENAI_API_KEY='sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

### switch時の自動処理

`home-manager switch` 時に `secrets/plain-vim/secrets.env` が存在する場合、自動で処理する。

処理内容:

```text
secrets/plain-vim/secrets.env
  -> secrets/vim.yaml へSOPS暗号化
  -> secrets/plain-vim/secrets.env を削除
  -> files/vim/dotvimrc-secrets.template と secrets/vim.yaml から ~/.vimrc-secrets を生成
```

つまり、運用はこれだけでよい。

```bash
cat > secrets/plain-vim/secrets.env <<'EOF'
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

switch後、平文ファイルは削除される。

```bash
ls -la secrets/plain-vim
```

`secrets/vim.yaml` はGit管理する。
`secrets/plain-vim/secrets.env` はGit管理しない。

### `hm-vim-secrets`

Home Manager適用後、以下の補助コマンドが使える。

```bash
hm-vim-secrets init
hm-vim-secrets status
hm-vim-secrets sync
hm-vim-secrets sync --keep
hm-vim-secrets sync-if-present
hm-vim-secrets add
hm-vim-secrets deploy
hm-vim-secrets deploy --soft
hm-vim-secrets edit
```

#### 初期化

```bash
hm-vim-secrets init
```

#### 平文secrets.envから暗号化

```bash
cat > secrets/plain-vim/secrets.env <<'EOF'
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx
EOF

hm-vim-secrets sync
```

`sync` は `secrets/plain-vim/secrets.env` を `secrets/vim.yaml` に暗号化して取り込み、平文ファイルを削除する。

平文を残したい場合:

```bash
hm-vim-secrets sync --keep
```

#### switch時と同じ自動処理を手動実行

```bash
hm-vim-secrets sync-if-present
hm-vim-secrets deploy
```

#### 標準入力から追加

```bash
hm-vim-secrets add
```

`KEY=VALUE` 形式で貼り付け、最後に `Ctrl-D`。

例:

```text
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx
```

#### 暗号化済みsecretを直接編集

```bash
hm-vim-secrets edit
```

例:

```yaml
OPENAI_API_KEY: sk-...
ANTHROPIC_API_KEY: sk-ant-...
GEMINI_API_KEY: ...
```

編集後、反映する。

```bash
hm-vim-secrets deploy
```

またはHome Manager全体を反映する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

#### 復号して `.vimrc` を生成

```bash
hm-vim-secrets deploy
```

生成先:

```text
~/.vimrc
```

生成された `.vimrc` は `0600` になる。

```bash
ls -la ~/.vimrc
```

期待値:

```text
-rw------- ... ~/.vimrc
```

#### Home Manager switch時のsoft deploy

Home Manager activationでは以下を実行する。

```bash
hm-vim-secrets sync-if-present
hm-vim-secrets deploy --soft
```

`--soft` は、age keyや `secrets/vim.yaml` がまだ無い場合でもHome Manager switchを止めない。
ただし、`secrets/plain-vim/secrets.env` が存在するのにage keyが無い場合は、暗号化できないためswitchを止める。
平文secretを残したまま処理を進めないため。

### 導入する外部CLI

Vimプラグイン用の外部CLIとして、以下をHome Managerで入れる。

* python3
* universal-ctags
* w3m
* fzf
* ripgrep

Node.jsは `vim.nix` ではなく、`nodejs.nix` で管理する。

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

## SKK辞書 (eskk)

日本語入力プラグイン eskk が使う辞書のうち、**読み込み専用辞書**を Home Manager で配置する。

### `skkdict.nix`

`files/skkdict/SKK-JISYO.MY.LL.eucjp.gz`（gzip圧縮した辞書）を解凍し、
`~/.SKK-JISYO.MY.LL.eucjp` に通常の（store経由の）ファイルとして配置する。

```nix
skkDictMyLL = pkgs.runCommand "SKK-JISYO.MY.LL.eucjp" { } ''
  ${pkgs.gzip}/bin/gunzip -c ${./files/skkdict/SKK-JISYO.MY.LL.eucjp.gz} > "$out"
'';
home.file.".SKK-JISYO.MY.LL.eucjp".source = skkDictMyLL;
```

* 読み込み専用辞書なので store symlink で問題ない。
* **学習辞書**（`~/.skk-jisyo.utf8`）は可変ファイルのため Home Manager では管理しない
  （eskk が初回登録時に作成する）。

### eskkのパス解決 (クラウド優先・ローカルフォールバック)

`dotvimrc` の eskk 設定は、以下の3つを **クラウド(Google Drive)優先・ローカル退避**で解決する。
クラウド側のパスが有効（ファイル/ディレクトリが存在）ならそれを使い、無効ならローカルにフォールバックする。

| 用途 | クラウド (Google Drive) | ローカルフォールバック |
|---|---|---|
| eskk home (log等) | `<gdrive>/MyDocuments/apps/eskk` | `~/.eskk`（無ければeskkが自動生成） |
| 学習辞書 | `<gdrive>/MyDocuments/apps/skk/.skk-jisyo.utf8` | `~/.skk-jisyo.utf8` |
| 読み込み辞書 | `<gdrive>/MyDocuments/apps/skk/SKK-JISYO.MY.LL.eucjp` | `~/.SKK-JISYO.MY.LL.eucjp`（`skkdict.nix`が配置） |

判定は vimscript の `isdirectory()` / `filereadable()`（`expand()` で `~` 展開）で行う。

確認:

```vim
:echo g:eskk#directory
:echo g:eskk#large_dictionary
```

## Neovim との共存

`nvim.nix` が neovim 本体を導入し、`~/.config/nvim/init.vim` を
out-of-store symlink (`files/nvim/init.vim`) として配置する。
`~/.vimrc` と同じく、その場での編集がそのまま本リポジトリの変更になる。

`init.vim` は `nvim-from-vim` 方式で `~/.vimrc` (= `files/vim/dotvimrc`) を source し、
vim と nvim で設定を共有する。

```vim
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
```

* `runtimepath^=~/.vim` により、vim-plug 本体 (`~/.vim/autoload/plug.vim`) や
  プラグイン (`~/.vim/bundle`) を nvim でも共有する。
* nvim 固有の設定は、`dotvimrc` 内の `if has('nvim')` 分岐で処理される。

確認:

```bash
nvim +'echo $MYVIMRC' +qa     # 本体起動確認
readlink -f ~/.config/nvim/init.vim   # => files/nvim/init.vim を指す
```

クラウドが無い環境では、それぞれ `~/.eskk` と `~/.SKK-JISYO.MY.LL.eucjp` にフォールバックする。

