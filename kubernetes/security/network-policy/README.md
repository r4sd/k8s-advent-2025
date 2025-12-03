# Network Policy Examples

## ⚠️ Important: CNI Requirement

NetworkPolicy requires CNI support to enforce rules. **Flannel does NOT support NetworkPolicy**.

### CNI Comparison

| CNI | NetworkPolicy | L7 Policy | eBPF |
|-----|---------------|-----------|------|
| Flannel | ❌ | ❌ | ❌ |
| Calico | ✅ | ✅ | Optional |
| Cilium | ✅ | ✅ | ✅ |

### Current Cluster Status

This cluster uses **Flannel**, so NetworkPolicy resources will be created but NOT enforced.

### Options to Enable NetworkPolicy

1. **Replace CNI**: Migrate to Calico or Cilium (requires cluster rebuild)
2. **Calico Policy-Only Mode**: Run Calico alongside Flannel for policy enforcement only

## Files

- `default-deny.yaml` - Blocks all ingress/egress (Zero Trust baseline)
- `allow-specific.yaml` - Example of allowing specific pod-to-pod traffic
