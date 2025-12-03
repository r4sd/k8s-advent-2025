output "controlplane_name" {
  description = "Control Plane VM名"
  value       = hyperv_machine_instance.controlplane.name
}

output "controlplane_state" {
  description = "Control Plane VM状態"
  value       = hyperv_machine_instance.controlplane.state
}

output "worker_names" {
  description = "Worker Node VM名リスト"
  value       = [for worker in hyperv_machine_instance.workers : worker.name]
}

output "worker_states" {
  description = "Worker Node VM状態リスト"
  value       = [for worker in hyperv_machine_instance.workers : worker.state]
}

output "cluster_summary" {
  description = "クラスタ概要"
  value = {
    controlplane = {
      name   = hyperv_machine_instance.controlplane.name
      cpu    = var.controlplane_cpu
      memory = "${var.controlplane_memory_gb}GB"
      disk   = "${var.controlplane_disk_gb}GB"
    }
    workers = [
      for i, worker in hyperv_machine_instance.workers : {
        name   = worker.name
        cpu    = var.worker_cpu[i]
        memory = "${var.worker_memory_gb[i]}GB"
        disk   = "${var.worker_disk_gb[i]}GB"
      }
    ]
  }
}

output "network_info" {
  description = "ネットワーク情報"
  value = {
    external_switch = var.external_switch_name
    internal_switch = var.internal_switch_name
    note            = "MACアドレスは動的に割り当てられます"
  }
}
