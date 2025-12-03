# Talos Linux設定

このディレクトリには、Talos Linuxクラスタの設定ファイルとセットアップ手順が含まれています。

## 前提条件

### talosctlインストール

```bash
# macOS
brew install siderolabs/tap/talosctl

# バージョン確認
talosctl version
```

### kubectlインストール

```bash
# macOS
brew install kubectl

# バージョン確認
kubectl version --client
```

## セットアップ手順

### 1. Talos設定ファイル生成

```bash
cd talos/

# 設定ファイル生成
talosctl gen config homelab-cluster https://10.0.0.200:6443 \
  --output-dir ./ \
  --with-secrets secrets.yaml \
  --config-patch @patches/common.yaml \
  --config-patch-control-plane @patches/controlplane.yaml \
  --config-patch-worker @patches/worker.yaml
```

生成されるファイル：
- `controlplane.yaml` - Control Plane設定
- `worker.yaml` - Worker Node設定
- `talosconfig` - talosctl設定（クライアント用）
- `secrets.yaml` - クラスタシークレット（⚠️ gitignore）

### 2. 設定ファイルのカスタマイズ

生成された設定ファイルに、ネットワーク設定を追加します。

#### Control Plane (controlplane.yaml)

```yaml
machine:
  network:
    hostname: k8s-cp-01
    interfaces:
      - interface: eth0  # External NIC
        dhcp: false
        addresses:
          - 10.0.0.200/24
        routes:
          - network: 0.0.0.0/0
            gateway: 10.0.0.1
      - interface: eth1  # Internal NIC
        dhcp: false
        addresses:
          - 192.168.100.10/24
    nameservers:
      - 10.0.0.1
      - 8.8.8.8
```

#### Worker Node (worker.yaml)

各Workerで個別に設定が必要です。`worker-01.yaml`, `worker-02.yaml`, `worker-03.yaml` を作成：

**worker-01.yaml:**
```yaml
machine:
  network:
    hostname: k8s-worker-01
    interfaces:
      - interface: eth0
        dhcp: false
        addresses:
          - 10.0.0.201/24
        routes:
          - network: 0.0.0.0/0
            gateway: 10.0.0.1
      - interface: eth1
        dhcp: false
        addresses:
          - 192.168.100.11/24
```

**worker-02.yaml** と **worker-03.yaml** も同様に作成（IPアドレスを変更）。

### 3. Talos設定の適用

#### Control Plane初期化

```bash
# Control Planeに設定適用
talosctl apply-config \
  --insecure \
  --nodes 10.0.0.200 \
  --file controlplane.yaml

# 起動確認（数分かかる）
talosctl --nodes 10.0.0.200 dashboard
```

#### Worker Node初期化

```bash
# Worker 1
talosctl apply-config \
  --insecure \
  --nodes 10.0.0.201 \
  --file worker-01.yaml

# Worker 2
talosctl apply-config \
  --insecure \
  --nodes 10.0.0.202 \
  --file worker-02.yaml

# Worker 3 (監視専用)
talosctl apply-config \
  --insecure \
  --nodes 10.0.0.203 \
  --file worker-03.yaml
```

### 4. Kubernetesクラスタのブートストラップ

```bash
# Control Planeからクラスタをブートストラップ
talosctl bootstrap --nodes 10.0.0.200

# ブートストラップ完了まで待機（数分）
talosctl --nodes 10.0.0.200 health --wait-timeout 10m
```

### 5. kubeconfig取得

```bash
# kubeconfigを取得
talosctl kubeconfig --nodes 10.0.0.200

# クラスタ確認
kubectl get nodes

# 出力例：
# NAME            STATUS   ROLES           AGE   VERSION
# k8s-cp-01       Ready    control-plane   5m    v1.28.x
# k8s-worker-01   Ready    <none>          3m    v1.28.x
# k8s-worker-02   Ready    <none>          3m    v1.28.x
# k8s-worker-03   Ready    <none>          3m    v1.28.x
```

## Talos設定の詳細

### ネットワーク構成

| ノード | Hostname | External IP | Internal IP |
|--------|----------|-------------|-------------|
| Control Plane | k8s-cp-01 | 10.0.0.200 | 192.168.100.10 |
| Worker 1 | k8s-worker-01 | 10.0.0.201 | 192.168.100.11 |
| Worker 2 | k8s-worker-02 | 10.0.0.202 | 192.168.100.12 |
| Worker 3 | k8s-worker-03 | 10.0.0.203 | 192.168.100.13 |

### Kubernetes設定

**Pod CIDR:** 10.244.0.0/16
**Service CIDR:** 10.96.0.0/12

### CNI

Talos LinuxのデフォルトCNI（Flannel）を使用します。

## 運用コマンド

### ノード状態確認

```bash
# ダッシュボード表示
talosctl --nodes 10.0.0.200 dashboard

# ヘルスチェック
talosctl --nodes 10.0.0.200,10.0.0.201,10.0.0.202,10.0.0.203 health

# ノード情報
talosctl --nodes 10.0.0.200 get members
```

### ログ確認

```bash
# kubelet ログ
talosctl --nodes 10.0.0.200 logs kubelet

# システムログ
talosctl --nodes 10.0.0.200 dmesg
```

### アップグレード

```bash
# Talos Linuxアップグレード
talosctl --nodes 10.0.0.200 upgrade \
  --image ghcr.io/siderolabs/installer:v1.6.0

# Kubernetesアップグレード
talosctl --nodes 10.0.0.200 upgrade-k8s --to 1.29.0
```

### リセット

```bash
# ノードをリセット（再インストール）
talosctl --nodes 10.0.0.201 reset --graceful=false --reboot
```

## トラブルシューティング

### ノードに接続できない

**原因:**
- ネットワーク設定ミス
- Talos APIが起動していない

**確認:**

```bash
# Ping確認
ping 10.0.0.200

# Talos API確認（ポート50000）
nc -zv 10.0.0.200 50000
```

### クラスタがブートストラップできない

**原因:**
- etcdが起動していない
- Control Plane設定ミス

**確認:**

```bash
# etcd状態確認
talosctl --nodes 10.0.0.200 service etcd status

# kubelet状態確認
talosctl --nodes 10.0.0.200 service kubelet status
```

### Worker Nodeが参加しない

**原因:**
- Worker設定のjoinトークンが間違っている
- ネットワーク接続問題

**確認:**

```bash
# Worker側のkubeletログ
talosctl --nodes 10.0.0.201 logs kubelet

# Control PlaneからWorker確認
kubectl get nodes
kubectl describe node k8s-worker-01
```

## ディレクトリ構成

```
talos/
├── README.md                # このファイル
├── patches/                 # 設定パッチ
│   ├── common.yaml         # 全ノード共通設定
│   ├── controlplane.yaml   # Control Plane追加設定
│   └── worker.yaml         # Worker追加設定
├── controlplane.yaml        # Control Plane設定（生成後）
├── worker-01.yaml           # Worker 1設定（生成後）
├── worker-02.yaml           # Worker 2設定（生成後）
├── worker-03.yaml           # Worker 3設定（生成後）
├── talosconfig              # talosctl設定（gitignore）
└── secrets.yaml             # クラスタシークレット（gitignore）
```

## セキュリティ

### 機密ファイル

以下のファイルは **絶対にコミットしない**：

- `talosconfig` - talosctl認証情報
- `secrets.yaml` - クラスタシークレット
- `*.secret` - すべてのシークレットファイル

`.gitignore` で除外されていることを確認：

```bash
cat ../../.gitignore | grep talos
```

### mTLS認証

Talos APIはmTLS（相互TLS認証）を使用します：

- クライアント証明書: `talosconfig` に含まれる
- サーバー証明書: 各ノードで自動生成

## 参考

- [Talos Linux公式ドキュメント](https://www.talos.dev/)
- [Talos on Hyper-V](https://www.talos.dev/v1.5/talos-guides/install/virtualized-platforms/hyper-v/)
- [talosctl CLI Reference](https://www.talos.dev/v1.5/reference/cli/)
