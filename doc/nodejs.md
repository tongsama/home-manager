# Node.js / npm 設定

## Node.js / npm設定

Node.jsは `nodejs.nix` で管理する。

方針:

* ベースの `nodejs` はNixで入れる
* よく使うCLIはできるだけNixで入れる
* プロジェクトごとの依存は、各プロジェクトの `package.json` / `node_modules` で管理する
* `npm install -g` を使いたい場合だけ、HOME配下のnpm global領域へ逃がす
* nvm / nodenv 利用中は、その node/npm 挙動を邪魔しない

Nixで入れた `nodejs` には通常 `npm` も含まれる。
ただし、Nix管理のNode.js/npmでそのまま `npm install -g` を実行すると、global install先が書き込み不可のNix store側に寄って失敗することがある。

そのため、このリポジトリではnpm global install用の領域をHOME配下に用意する。

```text
~/.local/share/npm-global
```

実行ファイルは以下に置かれる。

```text
~/.local/share/npm-global/bin
```

このbinディレクトリは `hm-extra.d/npm-global.bash` からPATHへ追加する。

### `nodejs.nix`

例:

```nix
{ lib, config, pkgs, ... }:

let
  npmGlobalDir = "${config.home.homeDirectory}/.local/share/npm-global";
in
{
  home.packages = with pkgs; [
    nodejs

    # よく使うならNixで入れる方が安定
    yarn
  ];

  home.activation.ensureNpmGlobalDir =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${lib.escapeShellArg npmGlobalDir}
    '';

  home.file.".config/bash/hm-extra.d/npm-global.bash".text = ''
    # Managed by Home Manager

    export NPM_GLOBAL_DIR="$HOME/.local/share/npm-global"

    path_prepend "$NPM_GLOBAL_DIR/bin"

    # Nixで入れたnodejs/npmを使っている時だけ、npm -g のprefixをHOME配下へ逃がす。
    # nvm(NVM_BIN) や nodenv(NODENV_ROOT) を使っている時は、その node/npm 挙動を邪魔しない。
    npm() {
      if [ -z "''${NVM_BIN:-}" ] && [ -z "''${NODENV_ROOT:-}" ]; then
        NPM_CONFIG_PREFIX="$NPM_GLOBAL_DIR" command npm "$@"
      else
        command npm "$@"
      fi
    }
  '';
}
```

### npm global install

新しいbashを開いた後、確認する。

```bash
type npm
echo "$NPM_GLOBAL_DIR"
npm config get prefix
```

期待値:

```text
npm is a function
/home/new_user/.local/share/npm-global
/home/new_user/.local/share/npm-global
```

例:

```bash
npm install -g yarn
which yarn
yarn --version
```

ただし、`yarn` のような常用CLIは、できれば `home.packages` でNix管理する。
`npm install -g` は、Nixpkgsに無いCLIや一時的に試したいCLI向けの逃げ道として使う。

### nvm / nodenv との共存

別のNode版管理を使っている場合、`npm` wrapper は `NPM_CONFIG_PREFIX` を上書きしない:

* nvm 利用中は `NVM_BIN` が立つ。
* nodenv (`modules.nodenv = true`) 利用中は `NODENV_ROOT` が立つ。

どちらかが設定されていれば wrapper は素通しし、その版管理側の node/npm 挙動をそのまま使う。

確認:

```bash
# nvm の場合
nvm use 22; echo "$NVM_BIN"; npm config get prefix
# nodenv の場合
nodenv version; echo "$NODENV_ROOT"; npm config get prefix
```

`~/.npmrc` に `prefix=...` を直接書くと、これらの版管理側のnpmにも影響することがある。
そのため、このリポジトリでは `~/.npmrc` にnpm global prefixを直接書かない。

