terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# SNS topic: single notification target for both Budgets and CloudWatch
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-cost-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

data "aws_iam_policy_document" "cost_alerts_topic_policy" {
  statement {
    sid    = "AllowBudgetsAndCloudWatchPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.cost_alerts.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "cost_alerts" {
  arn    = aws_sns_topic.cost_alerts.arn
  policy = data.aws_iam_policy_document.cost_alerts_topic_policy.json
}

# ---------------------------------------------------------------------------
# AWS Budgets: proactive, cost-purpose-built — actual + forecasted alerts
# ---------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly_cost" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_amount)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = var.actual_alert_threshold_pct
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }

  depends_on = [aws_sns_topic_policy.cost_alerts]
}

# ---------------------------------------------------------------------------
# CloudWatch billing alarm: billing-as-a-metric, same tooling as any other alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "billing" {
  alarm_name          = "${var.project_name}-billing-alarm"
  alarm_description   = "Triggers when estimated AWS charges exceed the monthly budget amount."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 hours — the EstimatedCharges metric itself only updates a few times/day
  statistic           = "Maximum"
  threshold           = var.budget_amount
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.cost_alerts.arn]

  depends_on = [aws_sns_topic_policy.cost_alerts]
}
