variable "api_gateway_id" {
  type        = string
  description = "Id of api gateway to configure Pagamentos api"
}

variable "api_gateway_root_resource_id" {
  type        = string
  description = "Id of api gateway root resource"
}

variable "authorizer_id" {
  type        = string
  description = "ID of API auhtorizer to protect routes"
}

variable "pagamentos_nlb_name" {
  type    = string
  description = "Name of network load balancer to create vpc link"
}
