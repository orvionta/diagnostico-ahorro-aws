# Diagnóstico de ahorro AWS — kit abierto

Material que uso en el **Diagnóstico de ahorro AWS** de [Orvionta](https://orvionta.com): el rol IAM de solo lectura que pido a cada cliente y la checklist de revisión de costes.

Lo publico abierto por dos motivos:

1. **Transparencia.** Antes de darme acceso a tu cuenta puedes leer, línea por línea, qué permisos pides y cuáles no.
2. **Que te sirva aunque no me contrates.** La checklist está pensada para que la revises tú mismo en una tarde.

---

## Contenido

| Ruta | Qué es |
|------|--------|
| [`iam/rol-diagnostico-solo-lectura.yaml`](iam/rol-diagnostico-solo-lectura.yaml) | Plantilla CloudFormation: rol IAM de solo lectura para facturación e inventario, **sin acceso a datos**. |
| [`checklist/checklist-ahorro-aws.md`](checklist/checklist-ahorro-aws.md) | 10 puntos (+1 extra) para pagar menos por AWS, con cómo revisarlos y el ahorro típico. |
| [`scripts/verificar-rol.sh`](scripts/verificar-rol.sh) | Comprueba con el simulador de políticas de IAM que el rol **no** puede leer datos, secretos ni modificar nada. |

---

## El rol IAM: qué permite y qué no

**Permite leer:**

- Costes y facturación (Cost Explorer, Budgets, Savings Plans, Cost Optimization Hub, precios).
- Inventario que influye en el coste: instancias, discos, snapshots, IPs, NAT Gateways, balanceadores, RDS, DynamoDB (solo la definición de la tabla), ElastiCache.
- Configuración de S3 (ciclo de vida, etiquetas, Intelligent-Tiering), **no los objetos**.
- Métricas de CloudWatch y la lista de grupos de logs, **no su contenido**.
- Opcional: recomendaciones de Compute Optimizer.

**No permite:**

- Crear, modificar ni borrar ningún recurso.
- Leer objetos de S3, filas de DynamoDB, contenido de bases de datos ni de logs.
- Leer secretos (Secrets Manager), parámetros (SSM Parameter Store), variables de entorno de Lambda ni el *user data* de las instancias.

### Por qué no uso `ReadOnlyAccess`

La política gestionada `ReadOnlyAccess` de AWS es cómoda, pero da mucho más de lo necesario: incluye, entre otras cosas, `s3:GetObject` (leer todos tus ficheros) y lectura de muchos servicios que no tienen nada que ver con el coste. Para un diagnóstico de costes, eso es exceso de privilegio. Este rol aplica **mínimo privilegio**: solo las acciones que necesito.

### Medidas de seguridad del rol

- **External ID** obligatorio en la relación de confianza: evita el problema del *confused deputy* (que otra persona use mi cuenta para asumir tu rol). Cada cliente tiene uno distinto.
- **Sesiones de 1 hora como máximo** (`MaxSessionDuration: 3600`).
- **Retirada inmediata:** al borrar el stack de CloudFormation, el acceso desaparece.
- Toda asunción del rol queda registrada en **CloudTrail** de tu cuenta (`AssumeRole`).

### Cómo desplegarlo

1. Consola de AWS → **CloudFormation** → *Crear stack* → *Con recursos nuevos* → sube `iam/rol-diagnostico-solo-lectura.yaml`.
2. Parámetros:
   - `ConsultantAccountId`: ID de la cuenta desde la que se asume el rol (te lo envío por correo).
   - `ExternalId`: identificador único para tu cuenta (te lo envío por correo).
   - `IncludeComputeOptimizer`: `si` solo si ya tienes Compute Optimizer activado.
3. Marca la casilla de que CloudFormation creará recursos de IAM y crea el stack.
4. En la pestaña *Salidas* copia el `RoleArn` y envíamelo.

Al terminar el diagnóstico: **borra el stack**.

Con la CLI:

```bash
aws cloudformation deploy \
  --template-file iam/rol-diagnostico-solo-lectura.yaml \
  --stack-name orvionta-diagnostico \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ConsultantAccountId=<ID_12_DIGITOS> ExternalId=<EXTERNAL_ID>

# Retirar el acceso
aws cloudformation delete-stack --stack-name orvionta-diagnostico
```

### Verificarlo tú mismo

Una vez desplegado, puedes comprobar que el rol no puede hacer lo que no debe:

```bash
./scripts/verificar-rol.sh
```

El script usa `aws iam simulate-principal-policy` (no ejecuta ninguna acción real) y muestra `allowed` / `implicitDeny` para un conjunto de acciones sensibles (leer objetos de S3, secretos, borrar instancias…). Todas deben salir **denegadas**. Funciona en Linux, macOS y Git Bash en Windows.

**Probado el 12-nov-2026** desplegando el rol en una cuenta y asumiéndolo desde otra:

| Prueba | Resultado |
|--------|-----------|
| Asumir el rol sin External ID | Denegado |
| Leer costes (Cost Explorer) e inventario (EBS) | Permitido |
| Leer un objeto de S3 | `AccessDenied` |
| Listar secretos (Secrets Manager) | `AccessDenied` |
| Leer el *user data* de una instancia | `UnauthorizedOperation` |
| Borrar un volumen o crear un snapshot (*dry-run*) | `UnauthorizedOperation` |

---

## Diagnóstico profesional

Si prefieres que lo revise yo: diagnóstico en 5 días laborables con este rol de solo lectura, e informe con cada hallazgo, su ahorro estimado y la prioridad. Condiciones y contacto en **[orvionta.com](https://orvionta.com)**.

Artículo relacionado: [Qué mirar cuando sube la factura de AWS](https://orvionta.com/recursos/que-mirar-cuando-sube-factura-aws/).

---

## Licencia

- Plantilla y scripts: [MIT](LICENSE).
- Checklist y documentación: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es) — puedes reutilizarla citando la fuente.

Precios y porcentajes de referencia (noviembre de 2026). Pueden variar por región y cambiar con el tiempo; verifícalos en la calculadora de precios de AWS antes de decidir.
