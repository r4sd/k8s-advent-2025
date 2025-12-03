# Terraform Hyper-V Infrastructure

このディレクトリには、Hyper-V上でKubernetesクラスタ用のVMを作成するTerraformコードが含まれています。

## 前提条件

### 1. Hyper-V設定

Hyper-Vホスト（Windows）で以下の準備が必要です：

#### WinRM有効化

PowerShell（管理者権限）で実行：

```powershell
# WinRM有効化
Enable-PSRemoting -Force

# HTTPSリスナー設定
winrm quickconfig -transport:https

# 認証設定
Set-Item WSMan:\localhost\Service\Auth\Basic $true
Set-Item WSMan:\localhost\Service\Auth\CredSSP $true

# ファイアウォール許可
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
```

#### 仮想スイッチ作成

```powershell
# External Switch（既存の internetSW を使用）
# 既に存在する場合はスキップ
Get-VMSwitch -Name "internetSW"

# Internal Switch（既存の InternalSW を使用）
# 既に存在する場合はスキップ
Get-VMSwitch -Name "InternalSW"
```

#### Talos Linux ISOダウンロード

```powershell
# ISOディレクトリ作成
New-Item -ItemType Directory -Force -Path C:\ISOs

# Talos Linux ISOダウンロード
# https://github.com/siderolabs/talos/releases からダウンロード
# C:\ISOs\talos-amd64.iso として保存
```

### 2. 管理端末（MacBook Pro）設定

#### Terraformインストール

```bash
brew install terraform
terraform version  # >= 1.5.0
```

#### Hyper-Vプロバイダー認証情報設定

```bash
# terraform.tfvars作成
cp terraform.tfvars.example terraform.tfvars

# エディタで編集（必須項目を設定）
vim terraform.tfvars
```

**必須の変更箇所:**

```hcl
# terraform.tfvars

# 1. パスワード（必須）
hyperv_password = "YourActualPassword"  # 実際のパスワードに変更

# 2. Talos ISOパス（必須）
talos_iso_path = "H:\\ISO\\metal-amd64.iso"  # 実際のパスに変更

# 3. VM保存先（環境に応じて）
vm_storage_path = "D:\\homelab\\VMs"  # D または H ドライブ
```

その他の設定は `terraform.tfvars.example` を参照してください。

## 使い方

### 1. 初期化

```bash
cd terraform/hyperv
terraform init
```

### 2. プラン確認

```bash
terraform plan
```

### 3. VM作成

```bash
terraform apply
```

確認メッセージで `yes` を入力します。

### 4. 作成されたVMの確認

```bash
terraform output cluster_summary
```

出力例：

```hcl
cluster_summary = {
  controlplane = {
    cpu    = 2
    disk   = "20GB"
    memory = "4GB"
    name   = "k8s-cp-01"
  }
  workers = [
    {
      cpu    = 2
      disk   = "50GB"
      memory = "8GB"
      name   = "k8s-worker-01"
    },
    # ...
  ]
}
```

### 5. VM削除

```bash
terraform destroy
```

## ディレクトリ構成

```
terraform/hyperv/
├── versions.tf              # Terraformバージョン、プロバイダー設定
├── variables.tf             # 変数定義
├── main.tf                  # VMリソース定義
├── outputs.tf               # 出力値
├── terraform.tfvars.example # 設定ファイルサンプル
├── terraform.tfvars         # 実際の設定（gitignore）
└── README.md                # このファイル
```

## VM仕様

### Control Plane

| 項目 | 値 |
|------|-----|
| CPU | 2 cores |
| メモリ | 4 GB |
| ディスク | 20 GB |
| External IP | 10.0.0.200（ルーターで予約） |
| Internal IP | 192.168.100.10（Talos設定で指定） |

### Worker Node 1, 2

| 項目 | 値 |
|------|-----|
| CPU | 2 cores |
| メモリ | 8 GB |
| ディスク | 50 GB |
| External IP | 10.0.0.201, 202（ルーターで予約） |
| Internal IP | 192.168.100.11, 12（Talos設定で指定） |

### Worker Node 3 (監視専用)

| 項目 | 値 |
|------|-----|
| CPU | 4 cores |
| メモリ | 16 GB |
| ディスク | 100 GB |
| External IP | 10.0.0.203（ルーターで予約） |
| Internal IP | 192.168.100.13（Talos設定で指定） |

## ネットワーク構成

各VMには2つのNICがアタッチされます：

### NIC 1: External (internetSW)

- 用途: ユーザーアクセス、サービス公開
- IPレンジ: 10.0.0.0/24
- MACアドレス: 00:15:5D:10:00:XX（静的割り当て）

### NIC 2: Internal (InternalSW)

- 用途: 管理通信、メトリクス収集
- IPレンジ: 192.168.100.0/24
- MACアドレス: 00:15:5D:20:00:XX（静的割り当て）

## トラブルシューティング

### WinRM接続エラー

**エラー:**
```
Error: failed to create vm client: unknown error Post "https://10.0.0.100:5986/wsman"
```

**解決策:**

1. Hyper-VホストでWinRMサービス確認

```powershell
Get-Service WinRM
# Status: Running であることを確認
```

2. ファイアウォール確認

```powershell
Get-NetFirewallRule -DisplayName "WinRM HTTPS"
```

3. テスト接続（Hyper-Vホストから）

```powershell
Test-WSMan -ComputerName localhost -UseSSL
```

### VMが起動しない

**原因:**
- Talos ISO パスが間違っている
- VHD保存先ディレクトリが存在しない

**解決策:**

```powershell
# ISOパス確認
Test-Path C:\ISOs\talos-amd64.iso

# VMディレクトリ作成
New-Item -ItemType Directory -Force -Path C:\VMs\homelab
```

### MACアドレス重複

**エラー:**
```
Error: MAC address already in use
```

**解決策:**

`terraform.tfvars` でMACアドレスを変更：

```hcl
controlplane_external_mac = "00:15:5D:10:00:05"  # 未使用のアドレスに変更
```

## 次のステップ

VM作成後は、Talos Linuxの設定を行います：

1. [talos/README.md](../../talos/README.md) を参照
2. talosctl で各VMを初期化
3. Kubernetesクラスタをブートストラップ

## 参考

- [Hyper-V Terraform Provider](https://registry.terraform.io/providers/taliesins/hyperv/latest/docs)
- [Talos Linux on Hyper-V](https://www.talos.dev/v1.5/talos-guides/install/virtualized-platforms/hyper-v/)
- [WinRM設定ガイド](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)
