# Variable definitions and default values

variable "location" {
  type    = string
  default = "eastus 2"
}

variable prefix {}
variable adf_git {}
variable org {}
variable environment {}

variable "tags" {
  type = map(string)
}