# Royal Airlines

Aplicación móvil Flutter para la gestión y reserva de vuelos. El proyecto
integra una experiencia de pasajero, una API REST con Spring Boot y un módulo
de minería de datos.

## Arquitectura del proyecto

```text
Flutter  -- HTTP/REST -->  Spring Boot  -- bajo demanda -->  Python
                              |
                              v
                           MongoDB
```

- **Flutter:** interfaz móvil, navegación, validación y consumo de API.
- **Spring Boot:** API principal, autenticación, reservas y conexión con la
  base de datos.
- **Python:** procesamiento de minería de datos solicitado por Spring Boot
  cuando se necesitan resultados agregados.
- **MongoDB:** persistencia de usuarios, reservas y datos de operación.

Flutter no llama a Python directamente. Toda la comunicación de la aplicación
se realiza con los endpoints REST de Spring Boot.

## Funcionalidades

| Módulo | Función |
| --- | --- |
| Autenticación | Registro, inicio de sesión, sesión segura y cambio de contraseña. |
| Inicio | Selección de origen/destino, promociones y destinos destacados. |
| Vuelos | Búsqueda, filtros, comparación de tarifas y señales predictivas. |
| Reserva | Selección de tarifa, asientos, equipaje, extras, pasajeros y pago simulado. |
| Mis reservas | Historial y detalle de las reservas del pasajero. |
| Para ti | Perfil de viajero basado en el historial personal y comparación con la comunidad. |
| Perfil | Información de la cuenta y acceso a sus reservas. |

Todas las cuentas usan la misma experiencia de pasajero: no hay roles ni
pantallas administrativas.

## Minería de datos

La aplicación incluye dos resultados predictivos visibles:

1. **Perfil de viajero:** clasifica el historial personal en un arquetipo:
   Recién llegado, Cazador de ofertas, Explorador, Viajero frecuente o
   Viajero premium.
2. **Señales de búsqueda:** muestran probabilidad de ocupación, posible
   tendencia de precio y la mejor opción entre los vuelos encontrados.

El perfil se calcula localmente con un clustering explicable de
**centroide más cercano**. Usa cantidad de viajes, diversidad de destinos,
elección de tarifa económica y elección de tarifa premium.

La comparación con la comunidad se obtiene mediante:

```text
Flutter -> GET /v1/insights/community -> Spring Boot -> Python
```

Esto permite que Python procese datos agregados bajo demanda, sin mantener un
proceso de análisis activo permanentemente.

## API REST

El contrato completo para el backend está en
[docs/api-contract.md](docs/api-contract.md).

| Área | Endpoints principales |
| --- | --- |
| Autenticación | `POST /auth/register`, `POST /auth/login`, `GET /auth/me` |
| Inicio | `GET /airports`, `GET /promotions`, `GET /destinations` |
| Vuelos | `GET /flights/search`, `GET /flights/{flightId}` |
| Reserva y pago | `POST /bookings`, `POST /payments/confirm` |
| Historial | `GET /reservations`, `GET /reservations/{reservationId}` |
| Minería de datos | `GET /insights/community` |

Las rutas protegidas reciben el encabezado:

```text
Authorization: Bearer <token>
```

La app mantiene datos locales mientras el backend no esté disponible. Cuando
Spring Boot esté listo, se activa la conexión real sin cambiar pantallas ni
controladores:

```powershell
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para un teléfono físico, reemplace `http://10.0.2.2:8080` por la dirección IP
local o por la URL HTTPS pública del backend. La guía detallada está en
[docs/connection-guide.md](docs/connection-guide.md).

## Estructura

```text
lib/
  core/          configuración, red, tema y utilidades
  features/      módulos de la aplicación
  models/        modelos y conversión JSON
  services/      servicios REST
  shared/        widgets reutilizables
docs/
  api-contract.md
  connection-guide.md
tools/
  mock-backend.js
  verify_real_integration.dart
```

La secuencia de datos es:

```text
screen/widget -> controller -> repository -> service -> ApiClient
```

No se realizan llamadas HTTP directamente desde las pantallas.

## Ejecutar el proyecto

```powershell
flutter pub get
flutter run
```

### Validación

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

### Verificar REST sin esperar al backend final

El repositorio incluye un servidor de prueba que cumple el mismo contrato que
Spring Boot:

```powershell
# Terminal 1
node tools/mock-backend.js

# Terminal 2
dart run tools/verify_real_integration.dart
```

Este verificador prueba autenticación, aeropuertos, búsqueda de vuelos,
reservas, pago y `GET /insights/community`.

## Seguridad y persistencia

- El token de sesión se almacena con `flutter_secure_storage`.
- La sesión expira automáticamente después de siete días.
- Las reservas se guardan localmente por usuario y se conservan al cerrar
  sesión o reiniciar la aplicación.
- El pago es académico y simulado: no se almacena número completo de tarjeta
  ni CVV.
