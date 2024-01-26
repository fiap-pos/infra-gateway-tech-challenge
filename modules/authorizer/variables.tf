variable "lambda_authorizer_name" {
  type        = string
  description = "Name of the Lambda Authorizer function"
}

variable "api_gateway_id" {
  type        = string
  description = "ID of API gateway do configure lambda authorizer"
}
