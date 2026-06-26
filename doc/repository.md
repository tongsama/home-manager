# リポジトリ運用 (公開範囲・remote・Git管理対象)

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
* `secrets/plain-vim/` の中身をcommitしない
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

通常のGitHub SSH URL:

```bash
git remote remove origin
git remote add origin git@github.com:<owner>/<repo>.git
```

SSH configに `Host odgit` のようなaliasを定義している場合:

```bash
git remote remove origin
git remote add origin odgit:<owner>/<repo>.git
```

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

secrets/plain-vim/*
!secrets/plain-vim/.gitignore

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
secrets/plain-vim/*
秘密鍵の平文
API keyの平文
```

Gitに入れるsecretファイル:

```text
secrets/ssh.yaml
secrets/oci.yaml
secrets/vim.yaml
```

これらはSOPSで暗号化されている前提。

