variable "aws_region" {
  description = "Region where AWS resources will be created and used."
  default = "us-east-1"
}

variable "profile" {
  description = "AWS Credential profile terraform will look for."
  default = "dev-mfa"
}

variable "store_number" {
    description = "HEB Store number to check"
    default = "123"
}

variable "sns_topic" {
    description = "SNS Topic to deliver notification to"
    default = "arn:aws:sns:us-east-1:123456789012:test-snstopic"
}