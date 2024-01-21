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

variable "producao_nlb_name" {
  type    = string
  default = "nlb-producao-service"
}

variable "lambda_authorizer_name" {
  type        = string
  description = "Name of the Lambda Authorizer function"
  default     = "techChallengeLambdaAuthorizerFunction"
}
