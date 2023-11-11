resource "aws_api_gateway_rest_api" "tech_challenge_gw" {
  name = "tech-challenge"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_vpc_link" "tech_challenge_vpc_link" {
  name        = "tech-challenge-vpc-link"
  target_arns = ["arn:aws:elasticloadbalancing:us-east-1:244071861643:loadbalancer/net/aa4bea770168b40688a65ead096aef0f/26df0d61bcc2e5a7"]
}

resource "aws_api_gateway_resource" "pedidos_resource" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  parent_id   = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  path_part   = "pedidos"
}

resource "aws_api_gateway_method" "pedidos_get" {
  rest_api_id   = aws_api_gateway_rest_api.tech_challenge_gw.id
  resource_id   = aws_api_gateway_resource.pedidos_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tech_challenge_integration" {
  http_method = aws_api_gateway_method.pedidos_get.http_method
  resource_id = aws_api_gateway_resource.pedidos_resource.id
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id

  type                    = "HTTP"
  uri                     = "http://aa4bea770168b40688a65ead096aef0f-26df0d61bcc2e5a7.elb.us-east-1.amazonaws.com/pedidos"
  integration_http_method = "GET"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.tech_challenge_vpc_link.id
}


resource "aws_api_gateway_method_response" "pedidos_response_200" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  resource_id = aws_api_gateway_resource.pedidos_resource.id
  http_method = aws_api_gateway_method.pedidos_get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "tech_challenge_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  resource_id = aws_api_gateway_resource.pedidos_resource.id
  http_method = aws_api_gateway_method.pedidos_get.http_method
  status_code = aws_api_gateway_method_response.pedidos_response_200.status_code
}


resource "aws_api_gateway_deployment" "tech_challenge_deployment" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.pedidos_resource.id,
      aws_api_gateway_method.pedidos_get.id,
      aws_api_gateway_integration.tech_challenge_integration.id,
      aws_api_gateway_integration_response.tech_challenge_integration_response
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "tech_challenge_stage" {
  deployment_id = aws_api_gateway_deployment.tech_challenge_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.tech_challenge_gw.id
  stage_name    = "dev"
}
