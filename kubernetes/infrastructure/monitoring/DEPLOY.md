# 監視スタック デプロイ手順

## 前提条件

- Kubernetes クラスタが稼働中
- MetalLB + Ingress NGINX がセットアップ済み
- Helm 3.x インストール済み

## 1. Discord Webhook URL の設定

`values.yaml` の以下の箇所を更新:

```yaml
receivers:
  - name: discord
    webhook_configs:
      - url: "YOUR_DISCORD_WEBHOOK_URL"  # ← ここを実際のURLに変更
```

## 2. 監視専用ノードの準備

```bash
# ラベル付与
kubectl label node talos-np5-tbl node-role.kubernetes.io/monitoring=true

# Taint 設定（監視ワークロードのみ配置）
kubectl taint node talos-np5-tbl dedicated=monitoring:NoSchedule

# 確認
kubectl get node talos-np5-tbl --show-labels
kubectl describe node talos-np5-tbl | grep Taints
```

## 3. デプロイ方法

### Option A: Kustomize + Helm（推奨）

```bash
# Helm リポジトリ追加（初回のみ）
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# kustomize build で確認
kubectl kustomize --enable-helm kubernetes/infrastructure/monitoring/

# 適用
kubectl apply -k kubernetes/infrastructure/monitoring/ --enable-helm
```

### Option B: Helm 直接インストール

```bash
# Namespace 作成
kubectl create namespace monitoring

# Helm リポジトリ追加
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# インストール
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values kubernetes/infrastructure/monitoring/values.yaml
```

## 4. 確認

```bash
# Pod 起動確認
kubectl get pods -n monitoring

# 期待される出力（全て Running）:
# kube-prometheus-alertmanager-0
# kube-prometheus-grafana-xxx
# kube-prometheus-kube-state-metrics-xxx
# kube-prometheus-operator-xxx
# kube-prometheus-prometheus-0
# prometheus-node-exporter-xxx (各ノードに1つ)

# Service 確認
kubectl get svc -n monitoring
```

## 5. アクセス

### Grafana

```bash
# Ingress 経由（hosts 設定後）
# http://grafana.homelab.local

# Port Forward（テスト用）
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80

# デフォルト認証
# User: admin
# Password: admin (values.yaml で設定した値)
```

### Prometheus UI

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-prometheus 9090:9090
# http://localhost:9090
```

### AlertManager UI

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-alertmanager 9093:9093
# http://localhost:9093
```

## 6. hosts ファイル設定（ローカルアクセス用）

```bash
# /etc/hosts または C:\Windows\System32\drivers\etc\hosts
10.0.0.190  grafana.homelab.local
```

## トラブルシューティング

### Pod が Pending のまま

```bash
# ノードのラベル確認
kubectl get nodes --show-labels | grep monitoring

# Taint 確認
kubectl describe node talos-np5-tbl | grep Taints

# Pod のイベント確認
kubectl describe pod -n monitoring <pod-name>
```

### AlertManager が通知しない

```bash
# AlertManager 設定確認
kubectl get secret -n monitoring alertmanager-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# アクティブなアラート確認
kubectl port-forward -n monitoring svc/kube-prometheus-alertmanager 9093:9093
# http://localhost:9093/#/alerts
```
