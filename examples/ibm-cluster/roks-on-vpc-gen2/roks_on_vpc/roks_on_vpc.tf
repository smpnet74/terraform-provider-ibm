resource "random_id" "name1" {
  byte_length = 2
}

resource "random_id" "name2" {
  byte_length = 2
}

resource "random_id" "name3" {
  byte_length = 2
}

resource "ibm_is_vpc" "vpc1" {
  name = "vpc-${random_id.name1.hex}"
}

resource "ibm_is_public_gateway" "testacc_gateway1" {
    name = "public-gateway1"
    vpc = ibm_is_vpc.vpc1.id
    zone = "${var.region}-1"
}

resource "ibm_is_public_gateway" "testacc_gateway2" {
    name = "public-gateway2"
    vpc = ibm_is_vpc.vpc1.id
    zone = "${var.region}-2"
}

resource "ibm_is_public_gateway" "testacc_gateway3" {
    name = "public-gateway3"
    vpc = ibm_is_vpc.vpc1.id
    zone = "${var.region}-3"
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_tcp" {
    group = ibm_is_vpc.vpc1.default_security_group
    direction = "inbound"
    tcp {
        port_min = 30000
        port_max = 32767
    }
 }

resource "ibm_is_subnet" "subnet1" {
  name                     = "subnet-${random_id.name1.hex}"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway = ibm_is_public_gateway.testacc_gateway1.id
}

resource "ibm_is_subnet" "subnet2" {
  name                     = "subnet-${random_id.name2.hex}"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-2"
  total_ipv4_address_count = 256
  public_gateway = ibm_is_public_gateway.testacc_gateway2.id
}

resource "ibm_is_subnet" "subnet3" {
  name                     = "subnet-${random_id.name3.hex}"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-3"
  total_ipv4_address_count = 256
  public_gateway = ibm_is_public_gateway.testacc_gateway3.id
}

data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

resource "ibm_resource_instance" "kms_instance1" {
    name              = "test_kms"
    service           = "kms"
    plan              = "tiered-pricing"
    location          = "${var.region}"
}
  
resource "ibm_kms_key" "test" {
    instance_id = "${ibm_resource_instance.kms_instance1.guid}"
    key_name = "test_root_key"
    standard_key =  false
    force_delete = true
}

resource "ibm_container_vpc_cluster" "cluster" {
  name              = "${var.cluster_name}${random_id.name1.hex}"
  vpc_id            = ibm_is_vpc.vpc1.id
  kube_version      = var.kube_version
  flavor            = var.flavor
  worker_count      = var.worker_count
  resource_group_id = data.ibm_resource_group.resource_group.id
  entitlement       = var.entitlement
  cos_instance_crn  = var.cos_instance_crn

  zones {
    subnet_id = ibm_is_subnet.subnet1.id
    name      = "${var.region}-1"
  }
  zones {
    subnet_id = ibm_is_subnet.subnet2.id
    name      = "${var.region}-2"
  }
  zones {
    subnet_id = ibm_is_subnet.subnet3.id
    name      = "${var.region}-3"
  }

  kms_config {
    instance_id = ibm_resource_instance.kms_instance1.guid
    crk_id = ibm_kms_key.test.key_id
    private_endpoint = false
  }

}

resource "ibm_container_vpc_worker_pool" "cluster_pool" {
  cluster           = ibm_container_vpc_cluster.cluster.id
  worker_pool_name  = "${var.worker_pool_name}${random_id.name1.hex}"
  flavor            = var.flavor
  vpc_id            = ibm_is_vpc.vpc1.id
  worker_count      = var.worker_count
  resource_group_id = data.ibm_resource_group.resource_group.id
  entitlement       = var.entitlement
  zones {
    subnet_id = ibm_is_subnet.subnet1.id
    name      = "${var.region}-1"
  }
  zones {
    subnet_id = ibm_is_subnet.subnet2.id
    name      = "${var.region}-2"
  }
  zones {
    subnet_id = ibm_is_subnet.subnet3.id
    name      = "${var.region}-3"
  }
}

resource "ibm_resource_instance" "sysdig" {
  name     = "TestMonitoring"
  service  = "sysdig-monitor"
  plan     = "graduated-tier"
  location = var.region
}

resource "ibm_ob_monitoring" "test2" {
  cluster     = ibm_container_vpc_cluster.cluster.id
  instance_id = ibm_resource_instance.sysdig.guid
}

resource "ibm_resource_instance" "logdna" {
  name     = "TestLogging"
  service  = "logdna"
  plan     = "7-day"
  location = var.region
}
resource "ibm_resource_key" "resourceKey" {
  name                 = "TestKey"
  resource_instance_id = ibm_resource_instance.logdna.id
  role                 = "Manager"
}

resource "ibm_ob_logging" "test3" {
  cluster     = ibm_container_vpc_cluster.cluster.id
  instance_id = ibm_resource_instance.logdna.guid
}

resource "ibm_container_addons" "addons" {
  cluster = ibm_container_vpc_cluster.cluster.name
  addons {
    name    = "kube-terminal"
    version = "1.0.0"
  }
}