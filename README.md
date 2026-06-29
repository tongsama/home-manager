# Home Manager configuration

Ubuntu上で、Nix Home Managerを使ってユーザ環境を再現するための設定。

このリポジトリは、既存のUbuntu標準設定をできるだけ壊さずに、ユーザ環境を宣言的・半宣言的に管理する。

主な管理対象:

* Nix flake
* Home Manager
* Bash追加設定
* Starship prompt
* Vim / gVim
* Neovim (vimと設定を共有)
* vim-plug本体
* Vimプラグイン用の外部CLI
* Vim設定ファイルの管理 (out-of-store symlink) とAPI key等のSOPS管理
* SKK辞書 (eskk)
* Node.js
* npm global install用のユーザ領域
* version manager (goenv / pyenv / rustup / nodenv / plenv、任意・既定無効)
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

README内では、対象ユーザ名をすべて `new_user` と表記する（実ユーザ名へ読み替える）。

詳細は下記ドキュメントを参照。

## ドキュメント

詳細は項目ごとに [`doc/`](doc/) 以下へ分割している。

| ドキュメント | 内容 |
|---|---|
| [doc/setup.md](doc/setup.md) | Nixインストール方針、Flakes有効化、初回セットアップ手順、`--impure`、通常の反映コマンド、よく使うコマンド |
| [doc/repository.md](doc/repository.md) | リポジトリの公開範囲、Git remote切り替え、`Git tree is dirty` warning、Git管理しないもの |
| [doc/modules.md](doc/modules.md) | ディレクトリ構成、`flake.nix` / `home.nix` / `gui.nix` / `wslg.nix` の要点 |
| [doc/bash.md](doc/bash.md) | Bash追加設定 (`hm-extra.bash` / `hm-extra.d`)、Starship、`NIX_HM_GOOGLEDRIVE_DIR` |
| [doc/vim.md](doc/vim.md) | Vim / gVim設定、out-of-store symlink、secret (SOPS) 管理、`hm-vim-secrets`、vim-plug、SKK辞書 (eskk)、Neovim共存 |
| [doc/nodejs.md](doc/nodejs.md) | Node.js / npm設定、npm global、nvm/nodenv共存 |
| [doc/fonts.md](doc/fonts.md) | フォント設定 |
| [doc/gui-input.md](doc/gui-input.md) | GUI profile、WSLg GUI設定、fcitx5 / Mozc |
| [doc/ssh.md](doc/ssh.md) | SSH設定、SSH秘密鍵管理 (age / `.sops.yaml` / `hm-ssh-secrets`) |
| [doc/oci.md](doc/oci.md) | OCI CLI設定、OCI API鍵管理 (`hm-oci-secrets`) |
| [doc/kubernetes.md](doc/kubernetes.md) | Kubernetes系CLI、OKE kubeconfig生成 |
| [doc/secrets-recovery.md](doc/secrets-recovery.md) | Secret復元手順、ユーザ作成からの復元テスト、Rollback、Home Manager撤退 |
| [doc/troubleshooting.md](doc/troubleshooting.md) | Troubleshooting、ユーザ名依存／平文secretの確認コマンド |

はじめての場合は [doc/setup.md](doc/setup.md) から読む。
