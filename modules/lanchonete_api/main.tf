data "aws_lb" "lanchonete_lb" {
  name = var.lanchonete_nlb_name
}

# --- Lanchonete nlb VPC link ---

resource "aws_api_gateway_vpc_link" "lanchonete_vpc_link" {
  name        = "tech-challenge-lanchonete-vpc-link"
  target_arns = [data.aws_lb.lanchonete_lb.arn]
}

# --- Lanchonete API configuration ---

resource "aws_api_gateway_resource" "lanchonete_resource" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_root_resource_id
  path_part   = "lanchonete"
}

# --- Lanchonete Pedidos configuration ---

resource "aws_api_gateway_resource" "lanchonete_pedidos" {
  rest_api_id = var.api_gateway_id
  parent_id   = aws_api_gateway_resource.lanchonete_resource.id
  path_part   = "pedidos"

  depends_on = [ aws_api_gateway_resource.lanchonete_resource ]
}

resource "aws_api_gateway_method" "lanchonete_pedidos_post"  {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.lanchonete_pedidos.id
  http_method   = "POST"

  authorization = "CUSTOM"
  authorizer_id = var.authorizer_id

  request_parameters = {
    "method.request.path.proxy" = true
  }

  depends_on = [ aws_api_gateway_resource.lanchonete_pedidos ]
}

resource "aws_api_gateway_integration" "lanchonete_pedidos_integration" {

  http_method = aws_api_gateway_method.lanchonete_pedidos_post.http_method
  resource_id = aws_api_gateway_resource.lanchonete_pedidos.id
  rest_api_id = var.api_gateway_id

  type                    = "HTTP_PROXY"  
  integration_http_method = "POST"
  uri                     = "http://${data.aws_lb.lanchonete_lb.dns_name}/pedidos"

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.lanchonete_vpc_link.id
  
  depends_on = [ aws_api_gateway_method.lanchonete_pedidos_post ]
}


# --- Lanchoente Proxy configuration ---


resource "aws_api_gateway_resource" "lanchonete_proxy" {
  rest_api_id = var.api_gateway_id
  parent_id   = aws_api_gateway_resource.lanchonete_resource.id
  path_part   = "{proxy+}"

  depends_on = [ aws_api_gateway_resource.lanchonete_resource ]
}

resource "aws_api_gateway_method" "lanchonete_proxy_any"  {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.lanchonete_proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }

  depends_on = [ aws_api_gateway_resource.lanchonete_proxy ]
}

resource "aws_api_gateway_integration" "lanchonete_proxy_integration" {

  http_method = aws_api_gateway_method.lanchonete_proxy_any.http_method
  resource_id = aws_api_gateway_resource.lanchonete_proxy.id
  rest_api_id = var.api_gateway_id

  type                    = "HTTP_PROXY"  
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.lanchonete_lb.dns_name}/{proxy}"

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
  
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.lanchonete_vpc_link.id

  depends_on = [ aws_api_gateway_method.lanchonete_proxy_any ]
}