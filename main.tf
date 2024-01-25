#----  API Gateway Configuration ----

resource "aws_api_gateway_rest_api" "tech_challenge_gw" {
  name = "tech-challenge-api-gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

#---- Lambda Authorizer Configuration ----

module "authorizer" {
  source = "./modules/authorizer"
  api_gateway_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  lambda_authorizer_name = var.lambda_authorizer_name
  depends_on = [ aws_api_gateway_rest_api.tech_challenge_gw ]
}

#---- Auth API configuration ----

module "auth_api" {
  source = "./modules/auth_api"
  api_gateway_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  api_gateway_root_resource_id = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  authorizer_id = module.authorizer.lambda_authorizer_id
  auth_nlb_name = var.auth_nlb_name
  depends_on = [ module.authorizer ]
}

#---- Lanchonete API configuration ----

module "lanchonete_api" {
  source = "./modules/lanchonete_api"
  api_gateway_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  api_gateway_root_resource_id = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  authorizer_id = module.authorizer.lambda_authorizer_id
  lanchonete_nlb_name = var.lanchonete_nlb_name
  depends_on = [ module.authorizer ]
}

#---- Producao API configuration ----

module "producao_api" {
  source = "./modules/producao_api"
  api_gateway_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  api_gateway_root_resource_id = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  authorizer_id = module.authorizer.lambda_authorizer_id
  producao_nlb_name = var.producao_nlb_name
  depends_on = [ module.authorizer ]
}

#---- Pagamentos API configuration ----

module "pagamentos_api" {
  source = "./modules/pagamentos_api"
  api_gateway_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  api_gateway_root_resource_id = aws_api_gateway_rest_api.tech_challenge_gw.root_resource_id
  authorizer_id = module.authorizer.lambda_authorizer_id
  pagamentos_nlb_name = var.pagamentos_nlb_name
  depends_on = [ moddule.auhtorizer ]
}

#---- Api Gateway Deployment ----

resource "aws_api_gateway_deployment" "dev_stage" {
  rest_api_id = aws_api_gateway_rest_api.tech_challenge_gw.id
  stage_name  = "dev" 

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.auth_api,
    module.lanchonete_api,
    module.pagamentos_api,
    module.producao_api
  ]
}

# Outputs

output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.dev_stage.invoke_url}"
}
