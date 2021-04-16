variable "ibmcloud_api_key" {
    default = "" 
}

variable "cos_service_name" {
    default = "smp-roks-myservice"
}

variable "cos_service_plan" {
    default = "standard"
}

variable "cluster_node_flavor" {
    default = "bx2.4x16"
}

variable "cluster_kube_version" {
    default = "4.6.22_openshift"
}

variable "default_worker_pool_count"{
    default = "2"
}

variable "region" {
  default = "us-south"
}

variable "resource_group" {
  default = "Default"
}

variable "cluster_name" {
  default = "smp-roks-cluster1"
}

variable "worker_pool_name" {
  default = "smp-roks-workerpool"
}

variable "entitlement"{
  default = ""
}