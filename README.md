# fastfood-api-gateway

Este repo contem configuracao do Terraform que estabelece um API Gateway com autorizadores e validadores.

Recursos
- **API Gateway**: fastfood_api_gateway - Nome do API Gateway.
- **Autorizador**: cognito_authorizer - Autorizador vinculado ao pool de usuários do Cognito.
- **Função AWS Lambda**: fastfood_lambda_authorizer - Destinada para a autorização.
- **Implantação**: fastfood-api-gateway-deployment - Processo de implantação do API Gateway.
- **Validador de Requisição**: validator - Responsável pela validação das requisições no API Gateway.