provider "aws" {
  region  = var.aws_region
  version = ">= 2.12"
  profile = var.profile
}


resource "aws_lambda_function" "heb_curbslide_lambda_func" {
  filename      = "heb_curbslide.zip"
  function_name = "heb_curbslide_lamda-store-${var.store_number}"
  role          = aws_iam_role.heb_curbslide_iam_role.arn
  handler       = "heb_curbslide.main"
  timeout       = "120"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("heb_curbslide.zip")

  runtime = "python3.6"

  environment {
    variables = {
      store_number   = "${var.store_number}"
      sns_topic   = "${var.sns_topic}"
      simpledb_domain   = aws_simpledb_domain.heb_checker.name
    }
  }
depends_on = [aws_iam_role.heb_curbslide_iam_role]

}


resource "aws_simpledb_domain" "heb_checker" {
  name = "last_heb_check"
}


# Create base IAM role
resource "aws_iam_role" "heb_curbslide_iam_role" {
  name               = "lambda-resource-heb_curbslide-${var.store_number}"
  assume_role_policy = data.aws_iam_policy_document.heb_curbslide_iam_policy_doc.json
}

# Add policy enabling access to other AWS services
resource "aws_iam_role_policy" "heb_curbslide_iam_policy" {
  name   = "lambda-${aws_lambda_function.heb_curbslide_lambda_func.id}-${var.store_number}"
  role   = aws_iam_role.heb_curbslide_iam_role.id
  policy = data.aws_iam_policy_document.heb_curbslide_iam_role_policy.json
}

# JSON POLICY - assume role
data "aws_iam_policy_document" "heb_curbslide_iam_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "heb_curbslide_iam_role_policy" {

  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "cloudwatch:PutMetricData",
      "sdb:PutAttributes",
      "sdb:Select"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [
      "${var.sns_topic}"
    ]
  }
}

resource "aws_cloudwatch_event_rule" "every_half_hour" {
    name = "every-half-hour"
    description = "Fires every half hour"
    schedule_expression = "rate(30 minutes)"
}

resource "aws_cloudwatch_event_target" "update_slots_every_half_hour" {
    rule = aws_cloudwatch_event_rule.every_half_hour.name
    target_id = "heb_curbslide_lambda_func"
    arn = aws_lambda_function.heb_curbslide_lambda_func.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_heb_curbslide_lambda_func" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.heb_curbslide_lambda_func.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_half_hour.arn
}