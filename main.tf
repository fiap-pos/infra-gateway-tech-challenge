data "aws_lb" "lanchonete_lb" {
  name = var.lanchonete_nlb_name
}

data "aws_lb" "auth_lb" {
  name = var.auth_nlb_name
}

data "aws_lb" "producao_lb" {
  name = var.producao_nlb_name
}

data "aws_lb" "pagamentos_lb" {
  name = var.pagamentos_nlb_name
}

data "aws_lambda_function" "lambda_authorizer" {
  function_name = var.lambda_authorizer_name
}

#---  API Gateway Configuration ---

resource "aws_api_gateway_rest_api" "tech_challenge_gw" {
  name = "tech-challenge-api-gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

#--- Lambda Authorizer Configuration ---

data "aws_iam_policy_document" "invocation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "invocation_role" {
  name               = "api_gateway_auth_invocation"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.invocation_assume_role.json
}

data "aws_iam_policy_document" "invocation_policy" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.lambda_authorizer.arn]
  }
}

resource "aws_iam_role_policy" "invocation_policy" {
  name   = "default"
  role   = aws_iam_role.invocation_role.id
  policy = data.aws_iam_policy_document.invocation_policy.json
}


resource "aws_api_gateway_authorizer" "tech_challenge_authorizer" {
  name                   = "tech-challenge-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.tech_challenge_gw.id
  
  authorizer_uri         = data.aws_lambda_function.lambda_authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
  authorizer_result_ttl_in_seconds = 0

  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
}

#---- VPC links ----

resource "aws_api_gateway_vpc_link" "auth_vpc_link" {
  name        = "tech-challenge-auth-vpc-link"
  target_arns = [data.aws_lb.auth_lb.arn]
}

resource "aws_api_gateway_vpc_link" "lanchonete_vpc_link" {
  name        = "tech-challenge-lanchonete-vpc-link"
  target_arns = [data.aws_lb.lanchonete_lb.arn]
}

resource "aws_api_gateway_vpc_link" "producao_vpc_link" {
  name        = "tech-challenge-producao-vpc-link"
  target_arns = [data.aws_lb.producao_lb.arn]
}

resource "aws_api_gateway_vpc_link" "pagamentos_vpc_link" {
  name        = "tech-challenge-pagamentos-vpc-link"
  target_arns = [data.aws_lb.pagamentos_lb.arn]
}

#---- Auth API configuration ----

resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  path_part   = "auth"

  depends_on = [ aws_api_gateway_rest_api.tech_challenge_gw ]
}

resource "aws_api_gateway_resource" "auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_resource.auth_resource.id
  path_part   = "{proxy+}"

  depends_on = [ aws_api_gateway_resource.auth_resource ]
}

resource "aws_api_gateway_method" "auth_any"  {
  rest_api_id   = aws_api_gateway_rest_api.tech_challenge_gw.id
  resource_id   = aws_api_gateway_resource.auth_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }

  depends_on = [ aws_api_gateway_resource.auth_proxy ]
}

resource "aws_api_gateway_integration" "auth_integration" {

  http_method = aws_api_gateway_method.auth_any.http_method
  resource_id = aws_api_gateway_resource.auth_proxy.id
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id

  type                    = "HTTP_PROXY"  
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.auth_lb.dns_name}/{proxy}"

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
  
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.auth_vpc_link.id

  depends_on = [ aws_api_gateway_method.auth_any ]
}

#---- Lanchonete API configuration ----

resource "aws_api_gateway_resource" "lanchonete_resource" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  path_part   = "lanchonete"

  depends_on = [ aws_api_gateway_rest_api.tech_challenge_gw ]
}

resource "aws_api_gateway_resource" "lanchonete_proxy" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_resource.lanchonete_resource.id
  path_part   = "{proxy+}"

  depends_on = [ aws_api_gateway_resource.lanchonete_resource ]
}

resource "aws_api_gateway_method" "lanchonete_any"  {
  rest_api_id   = aws_api_gateway_rest_api.tech_challenge_gw.id
  resource_id   = aws_api_gateway_resource.lanchonete_proxy.id
  http_method   = "ANY"

  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.tech_challenge_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true
  }

  depends_on = [ aws_api_gateway_resource.lanchonete_proxy ]
}

resource "aws_api_gateway_integration" "lanchonete_integration" {

  http_method = aws_api_gateway_method.lanchonete_any.http_method
  resource_id = aws_api_gateway_resource.lanchonete_proxy.id
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id

  type                    = "HTTP_PROXY"  
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.lanchonete_lb.dns_name}/{proxy}"

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
  
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.lanchonete_vpc_link.id

  depends_on = [ aws_api_gateway_method.lanchonete_any ]
}

#---- Producao API configuration ----

resource "aws_api_gateway_resource" "producao_resource" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  path_part   = "producao"

  depends_on = [ aws_api_gateway_rest_api.tech_challenge_gw ]
}

resource "aws_api_gateway_resource" "producao_proxy" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_resource.producao_resource.id
  path_part   = "{proxy+}"

  depends_on = [ aws_api_gateway_resource.producao_resource ]
}

resource "aws_api_gateway_method" "producao_any"  {
  rest_api_id   = aws_api_gateway_rest_api.tech_challenge_gw.id
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
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id

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

# --- Pagamentos API configuration ---
resource "aws_api_gateway_resource" "pagamentos_resource" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  path_part   = "pagamentos"

  depends_on = [ aws_api_gateway_rest_api.tech_challenge_gw ]
}

resource "aws_api_gateway_resource" "pagamentos_proxy" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_resource.pagamentos_resource.id
  path_part   = "{proxy+}"

  depends_on = [ aws_api_gateway_resource.pagamentos_resource ]
}

resource "aws_api_gateway_method" "pagamentos_any"  {
  rest_api_id   = aws_api_gateway_rest_api.tech_challenge_gw.id
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
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id

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

# Api Gateway Deployment

resource "aws_api_gateway_deployment" "dev_stage" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  stage_name  = "dev" 

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lanchonete_integration,
    aws_api_gateway_integration.auth_integration,
    aws_api_gateway_integration.producao_integration
  ]
}

# Outputs

output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.dev_stage.invoke_url}"
}
