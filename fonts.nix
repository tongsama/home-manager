{ pkgs, lib, ... }:

let
  mkGithubReleaseFont =
    { pname
    , owner ? "yuru7"
    , repo
    , tag
    , asset
    , hash
    }:

    pkgs.stdenvNoCC.mkDerivation {
      inherit pname;

      version = lib.removePrefix "v" tag;

      src = pkgs.fetchzip {
        url = "https://github.com/${owner}/${repo}/releases/download/${tag}/${asset}";
        inherit hash;

        # zip 内のディレクトリ構造がフォントごとに違っても拾えるようにする
        stripRoot = false;
      };

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        install -dm755 "$out/share/fonts"

        found=0

        while IFS= read -r -d "" font; do
          case "$font" in
            *.ttf|*.TTF|*.otf|*.OTF|*.ttc|*.TTC)
              install -m444 -Dt "$out/share/fonts" "$font"
              found=1
              ;;
          esac
        done < <(find "$src" -type f -print0)

        if [ "$found" -eq 0 ]; then
          echo "no font files found in $src" >&2
          exit 1
        fi

        runHook postInstall
      '';
    };

  yuru7Fonts = [
    (mkGithubReleaseFont {
      pname = "bizin-gothic-nf";
      repo = "bizin-gothic";
      tag = "v0.0.4";
      asset = "BizinGothicNF_v0.0.4.zip";
      hash = "sha256-t9plPSwUNWcZj257ETOtYSe2/jzWNt6/sPC0ePpF3Mg=";
    })

    # 追加例:
    #
    # (mkGithubReleaseFont {
    #   pname = "some-font-nf";
    #   repo = "some-font-repo";
    #   tag = "v1.2.3";
    #   asset = "SomeFont_v1.2.3.zip";
    #   hash = lib.fakeHash;
    # })
  ];
in
{
  fonts.fontconfig.enable = true;

  home.packages =
    yuru7Fonts
    ++ [
      # fc-list / fc-match 確認用。不要なら外してOK。
      pkgs.fontconfig
    ];
}
