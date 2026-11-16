# ---------- Trazabilidad (CloudTrail) ----------
# Registra quién hizo qué en la cuenta de AWS. Los registros se guardan en S3 (cifrado, privado)
# y también se envían a CloudWatch Logs para poder alertar sobre acciones sospechosas.

locals {
  trail_name   = "${var.project_name}-trail"
  trail_bucket = "${var.project_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  trail_arn    = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
}

resource "aws_s3_bucket" "trail" {
  bucket        = local.trail_bucket
  force_destroy = true # permite `terraform destroy` del ambiente de la evaluacion
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    id     = "expirar-registros-antiguos"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid       = "CloudTrailLeerAcl"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "CloudTrailEscribirRegistros"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "SoloConexionesCifradas"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.trail.arn, "${aws_s3_bucket.trail.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.trail]
}

# --- Envío de CloudTrail a CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "trail" {
  name              = "/${var.project_name}/cloudtrail"
  retention_in_days = var.log_retention_days
}

data "aws_iam_policy_document" "trail_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "trail_to_cloudwatch" {
  name               = "${var.project_name}-cloudtrail-to-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.trail_assume.json
}

data "aws_iam_policy_document" "trail_to_cloudwatch" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "trail_to_cloudwatch" {
  name   = "${var.project_name}-cloudtrail-logs"
  role   = aws_iam_role.trail_to_cloudwatch.id
  policy = data.aws_iam_policy_document.trail_to_cloudwatch.json
}

resource "aws_cloudtrail" "main" {
  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.trail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.trail_to_cloudwatch.arn

  depends_on = [aws_s3_bucket_policy.trail, aws_iam_role_policy.trail_to_cloudwatch]
}

# --- Alerta de seguridad: llamadas a la API no autorizadas o denegadas ---
resource "aws_cloudwatch_log_metric_filter" "unauthorized_calls" {
  name           = "${var.project_name}-llamadas-no-autorizadas"
  log_group_name = aws_cloudwatch_log_group.trail.name
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name          = "LlamadasNoAutorizadas"
    namespace     = "LogiFlow"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_calls" {
  alarm_name          = "${var.project_name}-llamadas-api-no-autorizadas"
  alarm_description   = "Se detectaron llamadas a la API de AWS denegadas (posible uso indebido de credenciales)"
  namespace           = "LogiFlow"
  metric_name         = "LlamadasNoAutorizadas"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.unauthorized_calls]
}
