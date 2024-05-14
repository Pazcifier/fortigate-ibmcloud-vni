data "ibm_is_ssh_key" "ssh_key" {
  name = var.ssh_public_key
}

resource "ibm_is_volume" "logDisk" {
  // Name must be lower case
  name    = "${var.cluster_name}-logdisk-${random_string.random_suffix.result}"
  profile = "10iops-tier"
  zone    = var.zone1
}

resource "ibm_is_floating_ip" "publicip" {
  name   = "${var.cluster_name}-publicip-${random_string.random_suffix.result}"
  target = ibm_is_instance.fgt1.primary_network_interface[0].id
}

resource "ibm_is_virtual_network_interface" "public-management"{
    name                                    = "public-management"
    allow_ip_spoofing               = false
    enable_infrastructure_nat   = true
    primary_ip {
        auto_delete       = false
    address             = "10.244.0.5"
    }
    subnet   = "0757-8394114c-d89c-41bf-9fa4-77478e833228"
}

resource "ibm_is_virtual_network_interface" "fna-lan"{
    name                                    = "fna-lan"
    allow_ip_spoofing               = false
    enable_infrastructure_nat   = true
    primary_ip {
        auto_delete       = false
    address             = "10.213.4.250"
    }
    subnet   = "0757-8cf9bd3c-48a1-4aa8-99ba-cd1e306fa7f0"
}

resource "ibm_is_virtual_network_interface" "bca-lan"{
    name                                    = "bca-lan"
    allow_ip_spoofing               = false
    enable_infrastructure_nat   = true
    primary_ip {
        auto_delete       = false
    address             = "10.213.8.82"
    }
    subnet   = "0757-a68f1496-804f-4eb2-8b7a-5557a0c25167"
}

resource "ibm_is_virtual_network_interface" "fna-wan"{
    name                                    = "fna-wan"
    allow_ip_spoofing               = false
    enable_infrastructure_nat   = true
    primary_ip {
        auto_delete       = false
    address             = "10.255.0.5"
    }
    subnet   = "0757-b20f4e6f-7e08-447a-a7dc-7c4b147508a2"
}

resource "ibm_is_virtual_network_interface" "bca-wan"{
    name                                    = "bca-wan"
    allow_ip_spoofing               = false
    enable_infrastructure_nat   = true
    primary_ip {
        auto_delete       = false
    address             = "10.255.0.21"
    }
    subnet   = "0757-0c06bd13-9d2f-4b22-a9ae-eec88a1dec41"
}

resource "ibm_is_instance" "fgt1" {
  name    = "${var.cluster_name}-fortigate-${random_string.random_suffix.result}"
  image   = ibm_is_image.vnf_custom_image.id
  profile = var.profile

  primary_network_attachment {
    name = "public-management"
    virtual_network_interface { 
      id = ibm_is_virtual_network_interface.public-management.id
    }
  }

  network_attachments {
    name = "fna-lan"
    virtual_network_interface { 
      id = ibm_is_virtual_network_interface.fna-lan.id
    }
  }

  volumes = [ibm_is_volume.logDisk.id]

  vpc       = data.ibm_is_vpc.vpc1.id
  zone      = var.zone1
  user_data = data.template_file.userdata.rendered
  keys      = [data.ibm_is_ssh_key.ssh_key.id]
}
// Use for bootstrapping cloud-init
data "template_file" "userdata" {
  template = file(var.user_data)
}