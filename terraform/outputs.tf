output "sns_topic_arn" {
  description = "ARN of the cost-alerts SNS topic."
  value       = aws_sns_topic.cost_alerts.arn
}

output "budget_name" {
  description = "Name of the AWS Budget."
  value       = aws_budgets_budget.monthly_cost.name
}

output "billing_alarm_name" {
  description = "Name of the CloudWatch billing alarm."
  value       = aws_cloudwatch_metric_alarm.billing.alarm_name
}
