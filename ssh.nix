{ config, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  home.file.".ssh/config".text = ''
    Host *
        KexAlgorithms +diffie-hellman-group1-sha1
        HostKeyAlgorithms +ssh-rsa
        PubkeyAcceptedAlgorithms +ssh-rsa
        ServerAliveInterval 120
        ServerAliveCountMax 86400
        TCPKeepAlive yes

    # private(tongsama)
    Host github.com
      HostName github.com
      User git
      IdentityFile ${homeDir}/.ssh/id_rsa_github_nopass

    # opendoor(kwatanabe777)
    Host odgit
      HostName github.com
      User git
      IdentityFile ${homeDir}/.ssh/id_rsa_github_od_nopass

    # gitea test
    Host localhost
      HostName localhost
      User git
      IdentityFile ${homeDir}/.ssh/id_rsa_github

    # forgejo(k8s) test
    Host git.test.dev-k8s.div1.opendoor.local
      HostName git.test.dev-k8s.div1.opendoor.local
      User git
      IdentityFile ${homeDir}/.ssh/id_rsa_github_nopass

    # huggingface
    Host hf.co
      HostName hf.co
      User git
      IdentityFile ${homeDir}/.ssh/id_rsa_hf

    # ME for codex remote
    Host odpc240501
      HostName odpc240501.tail864aae.ts.net
      User kwatanabe
      IdentityFile ${homeDir}/.ssh/id_rsa_github_nopass

    # for ls-rd env
    Host ls-rd.kgy.kp2.jp
      HostName ls-rd.kgy.kp2.jp
      User kwatanabe
      IdentityFile ${homeDir}/.ssh/id_rsa_kagoya
  '';


  home.file.".ssh/id_rsa_github.pub".source =          ./files/ssh/id_rsa_github.pub;
  home.file.".ssh/id_rsa_github_od.pub".source =       ./files/ssh/id_rsa_github_od.pub;
  home.file.".ssh/id_rsa_hf.pub".source =              ./files/ssh/id_rsa_hf.pub;
  home.file.".ssh/id_rsa_lambda-ai.pub".source =       ./files/ssh/id_rsa_lambda-ai.pub;
  home.file.".ssh/id_rsa_vastai.pub".source =          ./files/ssh/id_rsa_vastai.pub;
  #home.file.".ssh/id_rsa_kagoya.pub".source =          ./files/ssh/id_rsa_kagoya.pub;

}
