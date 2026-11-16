#!/usr/bin/env bash
# Verifica que el monitoreo, el logging y la trazabilidad estén operativos en AWS.
# Requiere AWS CLI con credenciales de lectura. Uso: ./scripts/verify_monitoring.sh [region] [proyecto]
set -euo pipefail
REGION="${1:-us-east-2}"
P="${2:-logiflow}"
export AWS_DEFAULT_REGION="$REGION"

echo "== Alarmas de CloudWatch =="
aws cloudwatch describe-alarms --alarm-name-prefix "$P-" \
  --query 'MetricAlarms[].[AlarmName,StateValue]' --output table

echo "== Grupos de logs =="
aws logs describe-log-groups --log-group-name-prefix "/$P/" \
  --query 'logGroups[].[logGroupName,retentionInDays]' --output table

echo "== Últimos logs de la aplicación =="
aws logs tail "/$P/app" --since 15m --format short | tail -n 10 || true

echo "== Estado de CloudTrail =="
aws cloudtrail get-trail-status --name "$P-trail" \
  --query '{Registrando:IsLogging,UltimaEntrega:LatestDeliveryTime}' --output table

echo "== Agente de CloudWatch (asociaciones SSM) =="
aws ssm list-associations --association-filter-list "key=AssociationName,value=$P-configurar-cloudwatch-agent" \
  --query 'Associations[].[AssociationName,Overview.Status]' --output table

echo "Para demostrar una alarma: aws cloudwatch set-alarm-state --alarm-name $P-cpu-alta --state-value ALARM --state-reason demo"
