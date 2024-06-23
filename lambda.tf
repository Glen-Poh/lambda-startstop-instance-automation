resource "aws_iam_role_policy" "lamdba_startstop_instances_policy" {
  name = "lamdba_startstop_instances_policy"
  role = aws_iam_role.lambda_startstop_instances_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeRegions",
          "ec2:start*",
          "ec2:stop*",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = "*"
      }]
  })
}

resource "aws_iam_role" "lambda_startstop_instances_role" {
  name = "lambda_startstop_instances_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = { Service = "lambda.amazonaws.com" }
      }]
  })
}

resource "aws_lambda_permission" "allow_stop_event" {
  statement_id  = "AllowExecutionFromEventStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_stop_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_instances.arn
}
resource "aws_lambda_permission" "allow_start_eventbridge" {
  statement_id  = "AllowExecutionFromeventbridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_start_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_instances.arn
}

data "archive_file" "lambda_stop_zip" {
  type        = "zip"
  source_file = "stop_instances_lambda.py"
  output_path = "stop_instances_lambda.zip"
}
data "archive_file" "lambda_start_zip" {
  type        = "zip"
  source_file = "start_instances_lambda.py"
  output_path = "start_instances_lambda.zip"
}

resource "aws_lambda_function" "lambda_stop_instances" {
  filename      = "stop_instances_lambda.zip"
  function_name = "lambda_stop_instances"
  role          = aws_iam_role.lambda_startstop_instances_role.arn
  handler       = "stop_instances_lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300
}

resource "aws_lambda_function" "lambda_start_instances" {
  filename      = "start_instances_lambda.zip"
  function_name = "lambda_start_instances"
  role          = aws_iam_role.lambda_startstop_instances_role.arn
  handler       = "start_instances_lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300
}
