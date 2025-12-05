# NetworkPolicy サンプル

## ⚠️ 重要: CNI の要件

NetworkPolicy のルールを適用するには、対応した CNI が必要です。**Flannel は NetworkPolicy をサポートしていません**。

### CNI 比較

| CNI | NetworkPolicy | L7 Policy | eBPF |
|-----|---------------|-----------|------|
| Flannel | ❌ | ❌ | ❌ |
| Calico | ✅ | ✅ | Optional |
| Cilium | ✅ | ✅ | ✅ |

### 現在のクラスタ状態

このクラスタは **Flannel** を使用しているため、NetworkPolicy リソースは作成されますが適用されません。

### NetworkPolicy を有効にする方法

1. **CNI の置き換え**: Calico または Cilium へ移行（クラスタ再構築が必要）
2. **Calico Policy-Only モード**: Flannel と併用し、ポリシー適用のみ Calico を使用

## ファイル

- `default-deny.yaml` - 全 Ingress/Egress をブロック（ゼロトラストのベースライン）
- `allow-specific.yaml` - 特定 Pod 間通信を許可するサンプル
