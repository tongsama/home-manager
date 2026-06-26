{ pkgs, ... }:

let
  # files/skkdict/*.gz を「元に戻して」(解凍して) ~ に配置する。
  # ここで配置するのは eskk の read-only 辞書 (g:eskk#large_dictionary) の
  # ローカルフォールバック先。クラウド (Google Drive) が使えない環境向け。
  #
  # 学習辞書 (~/.skk-jisyo.utf8) は可変ファイルなのでここでは管理しない。
  skkDictMyLL = pkgs.runCommand "SKK-JISYO.MY.LL.eucjp" { } ''
    ${pkgs.gzip}/bin/gunzip -c ${./files/skkdict/SKK-JISYO.MY.LL.eucjp.gz} > "$out"
  '';
in
{
  # ~/.SKK-JISYO.MY.LL.eucjp (dotvimrc のローカルフォールバックパスに対応)
  home.file.".SKK-JISYO.MY.LL.eucjp".source = skkDictMyLL;
}
