# ---------- Seguridad: identidad de la instancia (mínimo privilegio) ----------
# La instancia usa un rol IAM en lugar de claves de acceso guardadas en el servidor.

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    sid     = "EC2AsumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.project_name}-ec2-role"
  description        = "Rol de la instancia: enviar logs/metricas a CloudWatch y gestion por SSM"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Permite administrar la instancia con Session Manager y que SSM instale/configure el agente.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Política propia y acotada: solo escribe en los grupos de logs del proyecto
# y publica métricas únicamente en el espacio de nombres CWAgent.
data "aws_iam_policy_document" "cloudwatch_agent" {
  statement {
    sid = "EscribirLogsDelProyecto"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "${aws_cloudwatch_log_group.app.arn}:*",
      "${aws_cloudwatch_log_group.system.arn}:*",
    ]
  }

  statement {
    sid       = "PublicarMetricasDelAgente"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"] # PutMetricData no admite restringir por recurso; se limita por condición.

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CWAgent"]
    }
  }

  statement {
    sid       = "LeerConfiguracionDelAgente"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.cwagent_config.arn]
  }
}

resource "aws_iam_role_policy" "cloudwatch_agent" {
  name   = "${var.project_name}-cloudwatch-agent"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.cloudwatch_agent.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.app.name
}
