#need to create Internet gateway and attach it to VPC and Internet GW entry in route table to access alb from internet
resource "aws_api_gateway_rest_api" "this" {
  name        = "serverless-swagger-ui"
  description = "This is a test API Gateway to demonstrate the use of Swagger UI"

  body = templatefile("${path.module}/api-gateway-definition.yaml",
    {
      orders_handler_arn     = aws_lambda_function.orders_handler.arn
      swagger_ui_handler_arn = aws_lambda_function.swagger_ui_handler.arn
      users_handler_arn     = aws_lambda_function.users_handler.arn
    }
  )
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_lambda_function" "orders_handler" {
  function_name = "orders-handler"
  role          = aws_iam_role.orders_handler.arn

  filename         = data.archive_file.orders_handler.output_path
  source_code_hash = data.archive_file.orders_handler.output_base64sha256
  handler          = "orders.handler"
  runtime          = "nodejs18.x"
  vpc_config {
    subnet_ids         = aws_subnet.example[*].id
    security_group_ids = [aws_security_group.alb_sg.id]
  }

}

data "archive_file" "orders_handler" {
  type        = "zip"
  source_file = "${path.module}/src/orders/orders.js"
  output_path = "${path.module}/src/orders/orders.zip"
}

resource "aws_iam_role" "orders_handler" {
  name = "orders-handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  inline_policy {
    name   = "policy-8675309"
    policy = data.aws_iam_policy_document.inline_policy.json
  }
}
data "aws_iam_policy_document" "inline_policy" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "orders_handler" {
  role       = aws_iam_role.orders_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_lambda_permission" "orders_handler" {
  function_name = aws_lambda_function.orders_handler.function_name

  action     = "lambda:InvokeFunction"
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}
#===================================
resource "aws_lambda_function" "users_handler" {
  function_name = "users-handler"
  role          = aws_iam_role.users_handler.arn

  filename         = data.archive_file.users_handler.output_path
  source_code_hash = data.archive_file.users_handler.output_base64sha256
  handler          = "users.handler"
  runtime          = "nodejs18.x"
  vpc_config {
    subnet_ids         = aws_subnet.example[*].id
    security_group_ids = [aws_security_group.alb_sg.id]
  }

}

data "archive_file" "users_handler" {
  type        = "zip"
  source_file = "${path.module}/src/orders/orders.js"
  output_path = "${path.module}/src/orders/orders.zip"
}

resource "aws_iam_role" "users_handler" {
  name = "users-handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name   = "policy-8675309"
    policy = data.aws_iam_policy_document.inline_policy.json
  }
}

resource "aws_iam_role_policy_attachment" "users_handler" {
  role       = aws_iam_role.users_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_lambda_permission" "users_handler" {
  function_name = aws_lambda_function.users_handler.function_name

  action     = "lambda:InvokeFunction"
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}

#=========================================================================
data "archive_file" "commonLibs" {
  type = "zip"

  source_dir  = "${path.module}/src/swagger-ui/layers/commonLibs"
  output_path = "${path.module}/src/swagger-ui/build/commonLibs.zip"
}
resource "aws_lambda_function" "swagger_ui_handler" {
  function_name = "swagger-ui-handler"
  role          = aws_iam_role.swagger_ui_handler.arn

  filename         = data.archive_file.swagger_ui_handler.output_path
  source_code_hash = data.archive_file.swagger_ui_handler.output_base64sha256
  handler          = "app.handler"
  layers           = [aws_lambda_layer_version.swagger_ui_handler.arn]
  runtime          = "nodejs18.x"

  environment {
    variables = {
      API_ID = "b9vwch90p0"
      STAGE  = "dev"
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.example[*].id
    security_group_ids = [aws_security_group.alb_sg.id]
  }
#   environment {
#     variables = {
#       API_ID   = aws_api_gateway_rest_api.this.id
#       STAGE    = aws_api_gateway_stage.this.stage_name
#     }
#   }
}

data "archive_file" "swagger_ui_handler" {
  type        = "zip"
  source_file = "${path.module}/src/swagger-ui/app.js"
  output_path = "${path.module}/src/swagger-ui/app.zip"
}

resource "aws_lambda_layer_version" "swagger_ui_handler" {
  layer_name = "swagger-ui-commonLibs"
  filename         = data.archive_file.commonLibs.output_path
  source_code_hash = data.archive_file.commonLibs.output_base64sha256
  #filename            = "${path.module}/src/swagger-ui/build/commonLibs.zip"
  compatible_runtimes = ["nodejs18.x"]

  depends_on = [
    data.archive_file.commonLibs
  ]
}

resource "aws_iam_role" "swagger_ui_handler" {
  name = "swagger-ui-handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  inline_policy {
    name   = "policy-8675309"
    policy = data.aws_iam_policy_document.inline_policy.json
  }
}

resource "aws_iam_role_policy_attachment" "swagger_ui_handler_cloudwatch_access" {
  role       = aws_iam_role.swagger_ui_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "swagger_ui_handler_api_gateway_access" {
  role       = aws_iam_role.swagger_ui_handler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
}
resource "aws_lambda_permission" "swagger_ui_handler" {
  function_name = aws_lambda_function.swagger_ui_handler.function_name

  action     = "lambda:InvokeFunction"
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.swagger_ui_handler.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
}
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "dev"
}

output "swagger_ui_endpoint" {
  description = "Endpoint Swagger UI can be reached over"
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.ap-south-1.amazonaws.com/dev/v1/api-docs/"
}

# resource "aws_lambda_function" "example" {
#   function_name = "example_lambda"
#   handler       = "index.handler"
#   runtime       = "nodejs14.x"
#
#   role = aws_iam_role.lambda_exec.arn
#
#   filename         = "lambda_function_payload.zip" # Ensure this file exists and contains your Lambda code
#   source_code_hash = filebase64sha256("lambda_function_payload.zip")
# }

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.example[*].id
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "my-demo-internet-gw"
  }
}

resource "aws_route_table" "test" {
  vpc_id = aws_vpc.example.id

  # since this is exactly the route AWS will create, the route will be adopted
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "example" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = element(["ap-south-1a", "ap-south-1b"], count.index)
}

resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_lambda_function.swagger_ui_handler.arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition {
    path_pattern {
      values = ["/v1/api-docs", "/v1/api-docs/*"]
    }
  }

  condition {
    http_request_method {
      values = ["GET"]
    }
  }
}
resource "aws_lb_listener_rule" "health_check_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Health check Pass!!"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}
