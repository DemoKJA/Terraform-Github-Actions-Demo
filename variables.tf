
variable "sub" { type = string }
variable "client_secret" { type = string }
variable "client_id" { type = string }
variable "tenant_id" { type = string }

variable "location" {
  type    = string
  default = "eastus 2"
}


variable "prefix" {
  type    = string
  default = "kjatest"
}

