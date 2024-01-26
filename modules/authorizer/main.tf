data "aws_lambda_function" "lambda_authorizer" {
  function_name = var.lambda_authorizer_name
}

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

data "aws_iam_policy_document" "invocation_policy" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.lambda_authorizer.arn]
  }
}

resource "aws_iam_role" "invocation_role" {
  name               = "api_gateway_auth_invocation"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.invocation_assume_role.json
}


resource "aws_iam_role_policy" "invocation_policy" {
  name   = "default"
  role   = aws_iam_role.invocation_role.id
  policy = data.aws_iam_policy_document.invocation_policy.json
}


resource "aws_api_gateway_authorizer" "tech_challenge_authorizer" {
  name                   = "tech-challenge-authorizer"
  rest_api_id            = var.api_gateway_id
  
  authorizer_uri         = data.aws_lambda_function.lambda_authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
  authorizer_result_ttl_in_seconds = 0

  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
}