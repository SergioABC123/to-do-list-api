resource "aws_sns_topic" "alarms" {
  name = "todo-list-api-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  todo_alarms = {
    "ec2-cpu-high" = {
      title              = "CPU de la EC2"
      namespace          = "AWS/EC2"
      metric_name        = "CPUUtilization"
      dimensions         = { InstanceId = aws_instance.api.id }
      statistic          = "Average"
      threshold          = 70
      evaluation_periods = 2
    }

    "rds-errors" = {
      title              = "Errores de lectura o escritura en RDS"
      namespace          = "TodoListAPI"
      metric_name        = "RdsErrors"
      dimensions         = {}
      statistic          = "Sum"
      threshold          = 1
      evaluation_periods = 1
    }

    "task-read-latency" = {
      title              = "Latencia de lectura de tareas (ms)"
      namespace          = "TodoListAPI"
      metric_name        = "TaskReadLatency"
      dimensions         = {}
      statistic          = "Average"
      threshold          = 1000
      evaluation_periods = 2
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "todo" {
  for_each = local.todo_alarms

  alarm_name          = "todo-list-api-${each.key}"
  alarm_description   = each.value.title
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  dimensions          = each.value.dimensions
  statistic           = each.value.statistic
  period              = 300
  threshold           = each.value.threshold
  evaluation_periods  = each.value.evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_dashboard" "todo" {
  dashboard_name = "todo-list-api"

  dashboard_body = jsonencode({
    widgets = [
      for name, metric in local.todo_alarms : {
        type   = "metric"
        x      = index(keys(local.todo_alarms), name) * 8
        y      = 0
        width  = 8
        height = 6

        properties = {
          title  = metric.title
          region = var.aws_region
          view   = "timeSeries"
          period = 300
          stat   = metric.statistic
          metrics = [
            concat(
              [metric.namespace, metric.metric_name],
              flatten([for key, value in metric.dimensions : [key, value]])
            )
          ]
        }
      }
    ]
  })
}