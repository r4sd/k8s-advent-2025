# Hyper-V接続設定
variable "hyperv_user" {
  description = "Hyper-Vホストのユーザー名"
  type        = string
}

variable "hyperv_password" {
  description = "Hyper-Vホストのパスワード"
  type        = string
  sensitive   = true
}

variable "hyperv_host" {
  description = "Hyper-VホストのIPアドレス"
  type        = string
}

variable "hyperv_port" {
  description = "WinRM接続ポート"
  type        = number
}

variable "hyperv_https" {
  description = "HTTPS接続を使用するか"
  type        = bool
}

variable "hyperv_insecure" {
  description = "証明書検証をスキップするか"
  type        = bool
}

variable "hyperv_use_ntlm" {
  description = "NTLM認証を使用するか"
  type        = bool
}

variable "hyperv_timeout" {
  description = "タイムアウト（例: 300s）"
  type        = string
}

# ネットワーク設定
variable "external_switch_name" {
  description = "External仮想スイッチ名"
  type        = string
}

variable "internal_switch_name" {
  description = "Internal仮想スイッチ名"
  type        = string
}

# Talos Linuxイメージ
variable "talos_iso_path" {
  description = "Talos Linux ISOイメージのパス"
  type        = string
}

# Control Plane設定
variable "controlplane_name" {
  description = "Control Plane VM名"
  type        = string
}

variable "controlplane_cpu" {
  description = "Control Plane CPUコア数"
  type        = number
}

variable "controlplane_memory_gb" {
  description = "Control Plane メモリ（GB）"
  type        = number
}

variable "controlplane_disk_gb" {
  description = "Control Plane ディスク（GB）"
  type        = number
}

# Worker Node設定
variable "worker_count" {
  description = "Worker Nodeの台数"
  type        = number
}

variable "worker_name_prefix" {
  description = "Worker Node VM名のプレフィックス"
  type        = string
}

variable "worker_cpu" {
  description = "Worker Node CPUコア数（配列）"
  type        = list(number)
}

variable "worker_memory_gb" {
  description = "Worker Node メモリ（GB）（配列）"
  type        = list(number)
}

variable "worker_disk_gb" {
  description = "Worker Node ディスク（GB）（配列）"
  type        = list(number)
}

# VM共通設定
variable "vm_generation" {
  description = "VMの世代（1 or 2）"
  type        = number

  validation {
    condition     = contains([1, 2], var.vm_generation)
    error_message = "vm_generation must be 1 or 2."
  }
}

variable "vm_storage_path" {
  description = "VM VHDファイルの保存先"
  type        = string
}

# MACアドレス設定
variable "controlplane_mac_address" {
  description = "Control Plane External NIC MACアドレス"
  type        = string
}

variable "worker_mac_addresses" {
  description = "Worker Nodes External NIC MACアドレス（配列）"
  type        = list(string)
}
