# 10 puntos para pagar menos por AWS

Checklist práctica para revisar tu cuenta en una tarde. En cuentas sin gestión de costes es habitual encontrar entre un 20 % y un 40 % de ahorro.

> **Antes de empezar (gratis):** activa Cost Explorer, Cost Optimization Hub y Compute Optimizer, y crea un presupuesto con alertas en AWS Budgets. Revisa **todas las regiones**, no solo la principal.

---

### 1. IPs públicas que nadie usa
- [ ] Revisado

**Qué es:** desde febrero de 2024 AWS cobra cada IPv4 pública, esté en uso o no.
**Cómo revisarlo:** EC2 → Elastic IPs: busca las que no tienen instancia asociada. En Cost Explorer filtra por "Public IPv4" para ver el total mensual. Revisa también balanceadores de prueba olvidados.
**Ahorro típico:** unos 3,60 US$ al mes por cada IP.

### 2. Bases de datos en Extended Support
- [ ] Revisado

**Qué es:** cuando una versión de motor sale de soporte estándar, RDS la pasa a Extended Support y cobra un recargo por vCPU y hora. MySQL 8.0 en RDS entró en Extended Support el 1 de agosto de 2026.
**Cómo revisarlo:** consola de RDS: revisa la versión de cada base. En la factura busca líneas "Extended Support". Aplica lo mismo a clústeres EKS con versiones antiguas de Kubernetes.
**Ahorro típico:** cientos de dólares al mes por base; el recargo sube el tercer año.

### 3. Discos gp2 que pueden ser gp3
- [ ] Revisado

**Qué es:** gp3 cuesta un 20 % menos por GB que gp2 y da 3.000 IOPS y 125 MB/s de base, sin importar el tamaño.
**Cómo revisarlo:** EC2 → Volúmenes → filtra por tipo gp2 → Modificar → gp3. El cambio se hace en caliente. Actualiza también tus plantillas de Terraform o CloudFormation.
**Ahorro típico:** 20 % del gasto en EBS gp2.

### 4. Volúmenes sin adjuntar y snapshots viejos
- [ ] Revisado

**Qué es:** discos que quedaron tras borrar servidores y snapshots que nadie va a restaurar.
**Cómo revisarlo:** EC2 → Volúmenes: estado `available` = sin adjuntar. EC2 → Snapshots: ordena por fecha. Usa Data Lifecycle Manager para que los snapshots caduquen solos.
**Ahorro típico:** el 100 % de lo que se elimina.

### 5. Servidores sobredimensionados
- [ ] Revisado

**Qué es:** instancias EC2 y RDS con uso de CPU y memoria muy bajo de forma sostenida.
**Cómo revisarlo:** activa AWS Compute Optimizer (gratis) y revisa sus recomendaciones. Una CPU media por debajo del 10-20 % suele indicar que se puede bajar un tamaño.
**Ahorro típico:** cada tamaño menos suele ser alrededor del 50 % del coste de esa instancia.

### 6. Entornos de prueba encendidos 24/7
- [ ] Revisado

**Qué es:** una semana tiene 168 horas; un equipo usa desarrollo y pruebas unas 50.
**Cómo revisarlo:** programa el apagado y encendido con AWS Instance Scheduler o EventBridge + Lambda, usando etiquetas. Ojo: una base RDS detenida se vuelve a encender sola a los 7 días.
**Ahorro típico:** hasta un 70 % del cómputo de esos entornos.

### 7. Savings Plans y reservas
- [ ] Revisado

**Qué es:** pagar todo a precio *on-demand* cuando el consumo base es estable.
**Cómo revisarlo:** Cost Explorer → Savings Plans → Recomendaciones. Compra solo sobre el consumo mínimo estable, no sobre picos. Revisa también la cobertura y el uso de lo que ya compraste.
**Ahorro típico:** hasta un 72 % frente a *on-demand*, según el compromiso.

### 8. Instancias que pueden migrar a Graviton
- [ ] Revisado

**Qué es:** las instancias ARM (Graviton) suelen costar alrededor de un 20 % menos con igual o mejor rendimiento.
**Cómo revisarlo:** buenas candidatas: RDS, ElastiCache, OpenSearch y aplicaciones en Java, Python, Node, Go o PHP. Prueba primero en un entorno de pruebas.
**Ahorro típico:** alrededor del 20 % por instancia migrada.

### 9. Buckets S3 sin ciclo de vida
- [ ] Revisado

**Qué es:** datos antiguos en la clase Standard, versiones viejas acumuladas y cargas multiparte incompletas.
**Cómo revisarlo:** usa S3 Storage Lens para ver dónde está el volumen. Añade reglas de ciclo de vida o activa Intelligent-Tiering. Configura la caducidad de las versiones no actuales.
**Ahorro típico:** 40-90 % en los datos que pasan a clases frías.

### 10. Logs de CloudWatch sin retención
- [ ] Revisado

**Qué es:** por defecto, los grupos de logs nunca caducan y se acumulan durante años.
**Cómo revisarlo:** CloudWatch → Grupos de logs: ordena por tamaño almacenado y define una retención (por ejemplo 30 o 90 días). Si necesitas guardarlos más tiempo, expórtalos a S3.
**Ahorro típico:** lo almacenado de más; además, menos ruido al investigar.

---

### Extra: NAT Gateway y transferencia de datos

El NAT Gateway cobra por cada GB que procesa. Si tus servidores privados acceden mucho a S3 o DynamoDB, un **VPC Gateway Endpoint** (sin coste) evita ese cargo. Revisa también el tráfico entre zonas de disponibilidad.

---

¿Prefieres que lo revise yo? Diagnóstico con acceso de solo lectura ([ver el rol](../iam/rol-diagnostico-solo-lectura.yaml)) → **[orvionta.com](https://orvionta.com)**

*Precios y porcentajes de referencia (región us-east-1, noviembre de 2026). Pueden variar por región y cambiar con el tiempo. Licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es).*
