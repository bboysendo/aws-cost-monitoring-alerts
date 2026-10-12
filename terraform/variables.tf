variable "aws_region" {
  description = "AWS region. Must be us-east-1 — the AWS/Billing CloudWatch metric is only published there, regardless of where other resources live."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for alerting resources."
  type        = string
  default     = "cost-monitor"
}

variable "alert_email" {
  description = "Email address to receive budget and billing alarm notifications. You must confirm the SNS subscription email after apply."
  type        = string
}

variable "budget_amount" {
  description = "Monthly cost budget, in USD. Used for both the AWS Budget limit and the CloudWatch billing alarm threshold."
  type        = number
  default     = 20
}

variable "actual_alert_threshold_pct" {
  description = "Percentage of the budget at which to send an ACTUAL (already spent) cost alert."
  type        = number
  default     = 80
}
