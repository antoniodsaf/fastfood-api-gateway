# fastfood-api-gateway

Este repo contem configuracao do Terraform que estabelece um API Gateway com autorizadores e validadores.

### Recursos
- **API Gateway**: fastfood_api_gateway - Nome do API Gateway.
- **Autorizador**: cognito_authorizer - Autorizador vinculado ao pool de usuários do Cognito.
- **Função AWS Lambda**: fastfood_lambda_authorizer - Destinada para a autorização.
- **Implantação**: fastfood-api-gateway-deployment - Processo de implantação do API Gateway.
- **Validador de Requisição**: validator - Responsável pela validação das requisições no API Gateway.

## Rotas
Abaixo estao as rotas expostas pelo api-gateway.

### Rotas que requer autenticação

- GET /customers/{id}: Obter um cliente por ID.
- DELETE /customers/{id}: Excluir um cliente por ID.
- POST /orders: Criar um novo pedido.
- GET /orders/{id}: Obter um pedido por ID.
- GET /orders: Obter todos os pedidos.
- PUT /orders/{id}/status: Atualizar status do pedido.
- GET /orders-payment/order/{orderId}: Obter status do pagamento de um pedido.
- POST /products: Criar um novo produto.
- GET /products/category: Obter produtos por categoria.
- GET /products/{id}: Obter um produto por ID.
- PUT /products/{id}: Atualizar um produto por ID.
- DELETE /products/{id}: Excluir um produto por ID.

## Rotas publicas

- POST /auth: Rota para autenticação.
- POST /customers: Criar um novo cliente.
- POST /orders-payment/webhook/process: Atualizar o pedido como pago.