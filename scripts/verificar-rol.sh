#!/usr/bin/env bash
# Comprueba con el simulador de políticas de IAM que el rol de diagnóstico
# NO puede leer datos ni modificar recursos, y SÍ puede leer costes e inventario.
# No ejecuta ninguna acción real: solo simula.
#
# Uso: ./scripts/verificar-rol.sh [NOMBRE_DEL_ROL]
# Requiere: AWS CLI v2 con permiso iam:GetRole e iam:SimulatePrincipalPolicy en tu cuenta.
set -euo pipefail

ROLE_NAME="${1:-Orvionta-Diagnostico-SoloLectura}"
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

# Acciones que DEBEN estar denegadas
DENY=(
  s3:GetObject
  s3:PutObject
  s3:DeleteBucket
  dynamodb:Scan
  dynamodb:GetItem
  rds:DeleteDBInstance
  rds:ModifyDBInstance
  secretsmanager:GetSecretValue
  ssm:GetParameter
  lambda:GetFunctionConfiguration
  ec2:DescribeInstanceAttribute
  ec2:TerminateInstances
  ec2:RunInstances
  logs:GetLogEvents
  logs:FilterLogEvents
  iam:CreateUser
  iam:AttachRolePolicy
)

# Acciones que DEBEN estar permitidas
ALLOW=(
  ce:GetCostAndUsage
  ec2:DescribeVolumes
  ec2:DescribeAddresses
  rds:DescribeDBInstances
  s3:GetLifecycleConfiguration
  cloudwatch:GetMetricData
)

simulate() {
  aws iam simulate-principal-policy \
    --policy-source-arn "$ROLE_ARN" \
    --action-names "$@" \
    --query 'EvaluationResults[].[EvalActionName,EvalDecision]' \
    --output text | tr -d '\r'   # la CLI de AWS en Windows termina las líneas en CRLF
}

fail=0
echo "Rol: $ROLE_ARN"
echo
echo "== Deben estar DENEGADAS =="
while read -r action decision; do
  decision="${decision%$'\r'}"
  # Solo cuenta como correcto una denegación explícita o implícita
  if [[ "$decision" != *Deny ]]; then
    echo "  FALLO  $action -> $decision"; fail=1
  else
    echo "  ok     $action -> $decision"
  fi
done < <(simulate "${DENY[@]}")

echo
echo "== Deben estar PERMITIDAS =="
while read -r action decision; do
  decision="${decision%$'\r'}"
  if [[ "$decision" != "allowed" ]]; then
    echo "  FALLO  $action -> $decision"; fail=1
  else
    echo "  ok     $action -> $decision"
  fi
done < <(simulate "${ALLOW[@]}")

echo
if [[ $fail -eq 0 ]]; then
  echo "Resultado: correcto. El rol solo permite lo previsto."
else
  echo "Resultado: hay acciones fuera de lo previsto. Revisa la plantilla."
  exit 1
fi
