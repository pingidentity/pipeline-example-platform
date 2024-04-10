variable "pingone_username" {
  default = ""
  type    = string
}
variable "pingone_password" {
  default = ""
  type    = string
}
variable "pingone_region" {
  default = ""
  type    = string
}
variable "pingone_client_id" {
  default = ""
  type    = string
}
variable "pingone_client_secret" {
  default = ""
  type    = string
}
variable "pingone_environment_id" {
  default = ""
  type    = string
}
variable "pingone_davinci_environment_id" {
  default = ""
  type    = string
}
# variable "pingone_davinci_user_group_id" {
#   default = ""
#   type    = string
# }
variable "pingone_davinci_terraform_group_id" {
  default = ""
  type    = string
}
variable "pingone_environment_name" {
  description = "name that will be used when creating PingOne Environment"
  default     = "Platform-PROD"
  type        = string
}
variable "pingone_environment_type" {
  default = "PRODUCTION"
  type    = string
}
variable "pingone_license_id" {
  default = ""
  type    = string
}
