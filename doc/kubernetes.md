# Kubernetes / OKE

## Kubernetes / OKE

Kubernetes共通ツールは `k8s-tools.nix` で管理する。

```nix
let
  helm = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [
      helm-diff
    ];
  };
in
{
  home.packages = with pkgs; [
    kubectl
    helm
    helmfile
    k9s
  ];
}
```

注意:

`pkgs.kubernetes-helm` とwrap済み `helm` の両方を `home.packages` に入れない。
`bin/helm` が衝突する可能性がある。

確認:

```bash
kubectl version --client
helm version
helm plugin list
helm diff version
helmfile --version
k9s version
```

### OKE kubeconfig

OKE kubeconfig生成は `k8s-oci.nix` で管理する。

設定ファイル:

```text
~/.config/oke/default.env
```

例:

```bash
OCI_CLI_PROFILE=DEFAULT
OCI_REGION=ap-osaka-1

OKE_CLUSTER_ID=ocid1.cluster.oc1.ap-osaka-1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OKE_KUBE_ENDPOINT=PUBLIC_ENDPOINT

# memo only
OKE_PUBLIC_ENDPOINT=xxx.xxx.xxx.xxx:6443

KUBECONFIG_PATH=$HOME/.kube/config
```

補助コマンド:

```bash
oke-kubeconfig
```

実行内容:

```bash
oci ce cluster create-kubeconfig \
  --cluster-id "$OKE_CLUSTER_ID" \
  --file "$KUBECONFIG_PATH" \
  --region "$OCI_REGION" \
  --token-version 2.0.0 \
  --kube-endpoint "$OKE_KUBE_ENDPOINT" \
  --overwrite
```

Home Manager activation時にも自動実行する。
ただしOCI認証やネットワークに依存するため、失敗してもHome Manager switch自体は止めない。

手動再実行:

```bash
oke-kubeconfig
```

確認:

```bash
kubectl config current-context
kubectl get nodes
```

