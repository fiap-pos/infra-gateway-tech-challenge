variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "auth_nlb_name" {
  type    = string
  default = "nlb-auth-service"
}

variable "lanchonete_nlb_name" {
  type    = string
  default = "nlb-lanchonete-service"
}
