resource "aws_iam_role" "scheduler_role" {
  name = "event_scheduler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Sid       = ""
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "event_invoke_policy" {
  name = "event_invoke_policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["lambda:InvokeFunction"]
      Effect   = "Allow"
      Resource = aws_lambda_function.lambda_stop_instances.arn
      },
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.lambda_start_instances.arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "stop_instances" {
  name                = "stop_instances"
  description         = "Stop instances at a specific timing"
  schedule_expression = var.stop_time 
  role_arn            = aws_iam_role.scheduler_role.arn
}

resource "aws_cloudwatch_event_target" "stop_instances_lambda" {
  rule      = aws_cloudwatch_event_rule.stop_instances.name
  target_id = "StopInstances"
  arn       = aws_lambda_function.lambda_stop_instances.arn
}

resource "aws_cloudwatch_event_rule" "start_instances" {
  name                = "start_instances"
  description         = "Start instances at a specific timing"
  schedule_expression = var.start_time 
  role_arn            = aws_iam_role.scheduler_role.arn
}

resource "aws_cloudwatch_event_target" "start_instances_lambda" {
  rule      = aws_cloudwatch_event_rule.start_instances.name
  target_id = "StartInstances"
  arn       = aws_lambda_function.lambda_start_instances.arn
}


/*
resource "aws_scheduler_schedule" "stop_ec2" { # to try again need change role assuem role and lambda name
  name       = "stop_ec2"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 10 * * ? *)"
  schedule_expression_timezone = "Asia/Singapore"

  target {
    arn      = aws_lambda_function.lambda_startstop_ec2.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}
*/

