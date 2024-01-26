data "aws_lb" "producao_lb" {
  name = var.producao_nlb_name
}

# --- Produção nlb VPC link ---

resource "aws_api_gateway_vpc_link" "producao_vpc_link" {
  name        = "tech-challenge-producao-vpc-link"
  target_arns = [data.aws_lb.producao_lb.arn]
}

#---- Producao API configuration ----

resource "aws_api_gateway_resource" "producao_resource" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_root_resource_id
  path_part   = "producao"
}

resource "aws_api_gateway_resource" "producao_proxy" {
  rest_api_id = var.api_gateway_id
  parent_id   = aws_api_gateway_resource.producao_resource.id
  path_part   = "{proxy+}"

  depends_on = [ aws_api_gateway_resource.producao_resource ]
}

resource "aws_api_gateway_method" "producao_any"  {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.producao_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }

  depends_on = [ aws_api_gateway_resource.producao_proxy ]
}

resource "aws_api_gateway_integration" "producao_integration" {

  http_method = aws_api_gateway_method.producao_any.http_method
  resource_id = aws_api_gateway_resource.producao_proxy.id
  rest_api_id = var.api_gateway_id

  type                    = "HTTP_PROXY"  
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.producao_lb.dns_name}/{proxy}"

  cache_key_parameters = ["method.request.path.proxy"]

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
  
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.producao_vpc_link.id

  depends_on = [ aws_api_gateway_method.producao_any ]
}
