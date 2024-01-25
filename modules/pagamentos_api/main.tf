data "aws_lb" "pagamentos_lb" {
  name = var.pagamentos_nlb_name
}

# --- Pagamentos nlb VPC link ---

resource "aws_api_gateway_vpc_link" "pagamentos_vpc_link" {
  name        = "tech-challenge-pagamentos-vpc-link"
  target_arns = [data.aws_lb.pagamentos_lb.arn]
}

# --- Pagamentos API configuration ---

resource "aws_api_gateway_resource" "pagamentos_resource" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_root_resource_id
  path_part   = "pagamentos"

  depends_on = [ aws_api_gateway_rest_api.tech_challenge_gw ]
}

resource "aws_api_gateway_resource" "pagamentos_proxy" {
  rest_api_id = var.api_gateway_id
  parent_id   = aws_api_gateway_resource.pagamentos_resource.id
  path_part   = "{proxy+}"

  depends_on = [ aws_api_gateway_resource.pagamentos_resource ]
}

resource "aws_api_gateway_method" "pagamentos_any"  {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.pagamentos_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }

  depends_on = [ aws_api_gateway_resource.pagamentos_proxy ]
}

resource "aws_api_gateway_integration" "pagamentos_integration" {

  http_method = aws_api_gateway_method.pagamentos_any.http_method
  resource_id = aws_api_gateway_resource.pagamentos_proxy.id
  rest_api_id = var.api_gateway_id

  type                    = "HTTP_PROXY"  
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.pagamentos_lb.dns_name}/{proxy}"

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
  
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.pagamentos_vpc_link.id

  depends_on = [ aws_api_gateway_method.pagamentos_any ]
}

