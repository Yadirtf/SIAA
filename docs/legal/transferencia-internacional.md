# Transferencia internacional de datos (US-LEG-03)

Registro de la decisión de alojamiento y de las garantías exigidas por la Ley 1581 de 2012
(art. 26) y el Decreto 1377 de 2013 para la transferencia de datos personales fuera de Colombia.

## 1. Decisión de región (AC-01)

| Componente | Proveedor | Región | Motivo |
|---|---|---|---|
| Base de datos | MongoDB Atlas sobre AWS | N. Virginia, EE. UU. (`us-east-1`) | Ningún proveedor de los usados ofrece región en Colombia. Es la región disponible con menor latencia desde Colombia y la misma del servidor de aplicación. |
| API y worker | Render | Virginia, EE. UU. (`virginia`) | Render solo ofrece Oregon, Ohio, Virginia, Frankfurt y Singapur; Virginia es la más cercana. Mantenerla junto a la base de datos evita tráfico entre regiones. |

Alternativa evaluada: AWS São Paulo (`sa-east-1`). Se descartó porque Render no tiene región en
Sudamérica y separar API y base de datos añadiría latencia a cada marcaje.

La configuración aplicada está en [`docs/despliegue/backend-render.md`](../despliegue/backend-render.md).
Si la institución cambia de proveedor o región, debe actualizar esta tabla, la sección 6 de la
política (`backend/internal/platform/politica/politica.md`) y subir `politica.Version` para que los
titulares vuelvan a aceptarla.

## 2. Encargados y cláusulas contractuales (AC-02)

| Encargado | Servicio | Instrumento contractual |
|---|---|---|
| MongoDB, Inc. | Base de datos (Atlas) | Data Processing Agreement de MongoDB Atlas, con cláusulas contractuales tipo |
| Render Services, Inc. | Servidor de la aplicación | Data Processing Addendum de Render, con cláusulas contractuales tipo |

Las cláusulas deben exigir como mínimo: tratamiento solo según instrucciones de la institución,
confidencialidad, cifrado en tránsito y en reposo, aviso de incidentes, subencargados
identificados y devolución o eliminación de los datos al terminar el servicio.

**Pendiente de la institución:** suscribir ambos acuerdos con su representante legal y archivar la
copia firmada. El software no puede hacer esta firma; la política ya los referencia.

## 3. Información al titular (AC-03)

La sección 6 de la política publicada (`GET /privacidad/politica`, versión 1.1) informa la
transferencia, el país y la región, los encargados y cómo pedir copia de las cláusulas. Al
publicarse la versión 1.1, cada usuario debe aceptarla de nuevo antes de marcar (US-LEG-01).
