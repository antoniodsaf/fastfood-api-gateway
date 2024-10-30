data "aws_lb" "fastfoodlb" {
  arn = "arn:aws:elasticloadbalancing:us-east-1:152915761077:loadbalancer/net/acefd0536fd2040ee937c81cdcb208ca/6ef525f8f93148b8"
}

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

resource "aws_api_gateway_vpc_link" "fastfood-vpc-link" {
	name = "fastfood-vpc-link"
 	target_arns = [data.aws_lb.fastfoodlb.arn]
}

resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.get_swagger,
    aws_api_gateway_integration.get_swagger_assets,
    aws_api_gateway_integration.proxy
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

############################################
## [BEGIN] GENERIC ROUTES (auth required) ##
resource "aws_api_gateway_resource" "proxy" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	parent_id   = aws_api_gateway_rest_api.fastfood_api_gateway.root_resource_id
  	path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  	rest_api_id   = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id   = aws_api_gateway_resource.proxy.id
  	http_method   = "ANY"
  	authorization = "COGNITO_USER_POOLS"
  	authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

  	request_parameters = {
    	"method.request.path.proxy"           = true
    	"method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "proxy" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id = aws_api_gateway_resource.proxy.id
  	http_method = "ANY"
    
  	integration_http_method = "ANY"
  	type                    = "HTTP_PROXY"
  	uri                     = "http://${data.aws_lb.fastfoodlb.dns_name}:3000/{proxy}"
  	passthrough_behavior    = "WHEN_NO_MATCH"
  	content_handling        = "CONVERT_TO_TEXT"

  	request_parameters = {
      "integration.request.path.proxy"           = "method.request.path.proxy"
      "integration.request.header.Accept"        = "'application/json'"
      "integration.request.header.Authorization" = "method.request.header.Authorization"
  	}

  	connection_type = "VPC_LINK"
  	connection_id   = aws_api_gateway_vpc_link.fastfood-vpc-link.id
}
## [END] GENERIC ROUTES (auth required) ###
############################################

############################################
## [BEGIN] Swagger routes ##################
resource "aws_api_gateway_resource" "swagger_doc_resource" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	parent_id   = aws_api_gateway_rest_api.fastfood_api_gateway.root_resource_id
  	path_part   = "api"
}

resource "aws_api_gateway_method" "get_swagger_doc" {
  	rest_api_id   = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id   = aws_api_gateway_resource.swagger_doc_resource.id
  	http_method   = "GET"
  	authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_swagger" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id = aws_api_gateway_resource.swagger_doc_resource.id
  	http_method = aws_api_gateway_method.get_swagger_doc.http_method

  	integration_http_method = "GET"
  	type                    = "HTTP_PROXY"
  	uri                     = "http://${data.aws_lb.fastfoodlb.dns_name}:3000/api"
  	passthrough_behavior    = "WHEN_NO_MATCH"
  	content_handling        = "CONVERT_TO_TEXT"

  	connection_type = "VPC_LINK"
  	connection_id   = aws_api_gateway_vpc_link.fastfood-vpc-link.id
}

resource "aws_api_gateway_resource" "swagger_assets_resource" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  parent_id   = aws_api_gateway_resource.swagger_doc_resource.id
  path_part   = "{swagger-assets}"
}

resource "aws_api_gateway_method" "get_swagger_assets" {
  	rest_api_id   = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id   = aws_api_gateway_resource.swagger_assets_resource.id
  	http_method   = "GET"
  	authorization = "NONE"

  	request_parameters = {
    	"method.request.path.swagger-assets"  = true
    }
}

resource "aws_api_gateway_integration" "get_swagger_assets" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id = aws_api_gateway_resource.swagger_assets_resource.id
  	http_method = aws_api_gateway_method.get_swagger_assets.http_method

  	integration_http_method = "GET"
  	type                    = "HTTP_PROXY"
  	uri                     = "http://${data.aws_lb.fastfoodlb.dns_name}:3000/api/{swagger-assets}"
  	passthrough_behavior    = "WHEN_NO_MATCH"
  	content_handling        = "CONVERT_TO_TEXT"

    request_parameters = {
      "integration.request.path.swagger-assets" = "method.request.path.swagger-assets"
    }

  	connection_type = "VPC_LINK"
  	connection_id   = aws_api_gateway_vpc_link.fastfood-vpc-link.id
}

############################################
## [BEGIN] Public routes ###################
#---> POST /customers
resource "aws_api_gateway_resource" "customers_resource" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	parent_id   = aws_api_gateway_rest_api.fastfood_api_gateway.root_resource_id
  	path_part   = "customers"
}

resource "aws_api_gateway_method" "post_customers" {
  	rest_api_id   = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id   = aws_api_gateway_resource.customers_resource.id
  	http_method   = "POST"
  	authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_customers" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id = aws_api_gateway_resource.customers_resource.id
  	http_method = aws_api_gateway_method.post_customers.http_method

  	integration_http_method = "POST"
  	type                    = "HTTP_PROXY"
  	uri                     = "http://${data.aws_lb.fastfoodlb.dns_name}:3000/customers"
  	passthrough_behavior    = "WHEN_NO_MATCH"
  	content_handling        = "CONVERT_TO_TEXT"

  	connection_type = "VPC_LINK"
  	connection_id   = aws_api_gateway_vpc_link.fastfood-vpc-link.id
}

#---> POST /orders-payment/webhook/process
resource "aws_api_gateway_resource" "orders_payment_resource" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	parent_id   = aws_api_gateway_rest_api.fastfood_api_gateway.root_resource_id
  	path_part   = "orders-payment"
}

resource "aws_api_gateway_resource" "webhook_resource" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	parent_id   = aws_api_gateway_resource.orders_payment_resource.id
  	path_part   = "webhook"
}


resource "aws_api_gateway_resource" "webhook_process_payment_resource" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	parent_id   = aws_api_gateway_resource.webhook_resource.id
  	path_part   = "process"
}

resource "aws_api_gateway_method" "post_webhook_process_payment" {
  	rest_api_id   = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id   = aws_api_gateway_resource.webhook_process_payment_resource.id
  	http_method   = "POST"
  	authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_webhook" {
  	rest_api_id = aws_api_gateway_rest_api.fastfood_api_gateway.id
  	resource_id = aws_api_gateway_resource.webhook_process_payment_resource.id
  	http_method = aws_api_gateway_method.post_webhook_process_payment.http_method

  	integration_http_method = "POST"
  	type                    = "HTTP_PROXY"
  	uri                     = "http://${data.aws_lb.fastfoodlb.dns_name}:3000/orders-payment/webhook/process"
  	passthrough_behavior    = "WHEN_NO_MATCH"
  	content_handling        = "CONVERT_TO_TEXT"

  	connection_type = "VPC_LINK"
  	connection_id   = aws_api_gateway_vpc_link.fastfood-vpc-link.id
}

#---> POST /auth
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
## [END] Public routes #####################
############################################
