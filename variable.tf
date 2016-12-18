variable "azure-region"          { default = "uksouth" }
variable "cidr"                  { default = "10.0.0.0/24" }
variable "dns-ip"                { default = "8.8.8.8" }
variable "instance-name"         { default = "server01" }
variable "instance-type"         { default = "Standard_A1" }
variable "server-ip"             { default = "10.0.0.10" }

variable "ad-user"               { default = "adminuser" }
variable "ad-pwd"                { default = "S3cur3P@ssw0rd" }
variable "ad-domain"             { default = "example.com" }
variable "ad-netbios-name"       { default = "EXAMPLE" }

variable "azure_subscription_id" { }
variable "azure_client_id"       { }
variable "azure_client_secret"   { }
variable "azure_tenant_id"       { }