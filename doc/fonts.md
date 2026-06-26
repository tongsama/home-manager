# フォント設定

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

