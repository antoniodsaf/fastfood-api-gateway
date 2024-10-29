data "aws_lambda_function" "fastfood_lambda_authorizer" {
  function_name = "fastfood_lambda_authorizer"
}

resource "aws_api_gateway_rest_api" "fastfood_api_gateway" {
  name = "fastfood_api_gateway"
}

resource "aws_api_gateway_request_validator" "validator" {
  name                        = "validator"
  rest_api_id                 = aws_api_gateway_rest_api.fastfood_api_gateway.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name            = "cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.fastfood_api_gateway.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = ["arn:aws:cognito-idp:us-east-1:152915761077:userpool/us-east-1_UHOOXVZPC"]
}

resource "aws_api_gateway_deployment" "fastfood-api-gateway-deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "fastfood_lambda_authorizer_permission" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.fastfood_lambda_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.fastfood_api_gateway.execution_arn}/*"
}

## [BEGIN] AUTH ROUTES ##
resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.fastfood_api_gateway.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "auth_method" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api_gateway.id
  resource_id   = aws_api_gateway_resource.auth_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.fastfood_api_gateway.id
  resource_id             = aws_api_gateway_resource.auth_resource.id
  http_method             = aws_api_gateway_method.auth_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:152915761077:function:fastfood_lambda_authorizer/invocations"
}
## [END] AUTH ROUTES