# Control Plane VHD
resource "hyperv_vhd" "controlplane_vhd" {
  path = "${var.vm_storage_path}\\${var.controlplane_name}.vhdx"
  size = var.controlplane_disk_gb * 1024 * 1024 * 1024
}

# Control Plane VM
resource "hyperv_machine_instance" "controlplane" {
  name                 = var.controlplane_name
  generation           = var.vm_generation
  processor_count      = var.controlplane_cpu
  static_memory        = true
  memory_startup_bytes = var.controlplane_memory_gb * 1024 * 1024 * 1024

  # VHDディスク
  vm_firmware {
    enable_secure_boot = "Off"
  }

  # ネットワークアダプタ: External
  network_adaptors {
    name               = "External"
    switch_name        = var.external_switch_name
    static_mac_address = var.controlplane_mac_address
  }

  # ネットワークアダプタ: Internal
  network_adaptors {
    name        = "Internal"
    switch_name = var.internal_switch_name
  }

  # DVD Drive (Talos ISO)
  #  dvd_drives {
  #    controller_number   = 0
  #    controller_location = 1
  #    path                = var.talos_iso_path
  #  }

  # ハードディスク
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.controlplane_vhd.path
  }
}

# Worker Node VHDs
resource "hyperv_vhd" "worker_vhds" {
  count = var.worker_count
  path  = "${var.vm_storage_path}\\${var.worker_name_prefix}-${format("%02d", count.index + 1)}.vhdx"
  size  = var.worker_disk_gb[count.index] * 1024 * 1024 * 1024
}

# Worker Node VMs
resource "hyperv_machine_instance" "workers" {
  count                = var.worker_count
  name                 = "${var.worker_name_prefix}-${format("%02d", count.index + 1)}"
  generation           = var.vm_generation
  processor_count      = var.worker_cpu[count.index]
  static_memory        = true
  memory_startup_bytes = var.worker_memory_gb[count.index] * 1024 * 1024 * 1024

  # VHDディスク
  vm_firmware {
    enable_secure_boot = "Off"
  }

  # ネットワークアダプタ: External
  network_adaptors {
    name               = "External"
    switch_name        = var.external_switch_name
    static_mac_address = var.worker_mac_addresses[count.index]
  }

  # ネットワークアダプタ: Internal
  network_adaptors {
    name        = "Internal"
    switch_name = var.internal_switch_name
  }

  # DVD Drive (Talos ISO)
  #  dvd_drives {
  #    controller_number   = 0
  #    controller_location = 1
  #    path                = var.talos_iso_path
  #  }

  # ハードディスク
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.worker_vhds[count.index].path
  }
}
