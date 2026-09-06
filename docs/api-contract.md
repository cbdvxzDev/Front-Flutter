# Contrato de API de Royal Airlines

Este documento es el acuerdo entre Flutter y backend para el proyecto
universitario. La app usa JSON y todas las rutas parten de:

`{BASE_URL}/v1`

Mientras el backend no este disponible, Flutter mantiene `useMockApi: true` en
`lib/core/config/app_config.dart`.

> ¿Dudas sobre qué URL usar (localhost, IP del emulador, puerto) o
> cómo probar un endpoint sin depender de Flutter? Ver
> [connection-guide.md](connection-guide.md), tiene un ejemplo real con
> `curl` para `/auth/login`.

## Resumen rapido de endpoints (orden sugerido de implementacion)

| # | Metodo | Ruta | Requiere token | Notas |
|---|--------|------|:---:|-------|
| 1 | POST | `/auth/register` | No | Crea usuario y ya devuelve token |
| 2 | POST | `/auth/login` | No | |
| 3 | GET | `/auth/me` | Si | |
| 4 | PUT | `/auth/me` | Si | Editar perfil |
| 5 | POST | `/auth/change-password` | Si | |
| 6 | GET | `/airports` | No | |
| 7 | GET | `/promotions` | No | |
| 8 | GET | `/destinations` | No | |
| 9 | GET | `/flights/search` | No | Query params, ver seccion Vuelos |
| 10 | GET | `/flights/{flightId}` | No | |
| 11 | POST | `/bookings` | Si | Campo de monto: `totalPrice` |
| 12 | POST | `/payments/confirm` | Si | Campo de monto: `amount` (distinto al anterior) |
| 13 | GET | `/reservations` | Si | Filtra por el usuario del token, NO por query param |
| 14 | GET | `/reservations/{reservationId}` | Si | |
| 15 | GET | `/insights/community` | Si | Comparación agregada del usuario vs. la comunidad. Pendiente de definir formato final con Python |

Todas las rutas con "Requiere token" esperan el header
`Authorization: Bearer <token>` con el `token` recibido en login/registro.

## Reglas generales

- `Content-Type: application/json`
- `Accept: application/json`
- Las rutas protegidas reciben `Authorization: Bearer <token>`.
- Las fechas se envian en formato ISO 8601.
- Los precios se envian como numero en COP, sin separadores.
- Respuesta exitosa:

```json
{
  "success": true,
  "message": "Operation completed",
  "data": {}
}
```

- Respuesta con error:

```json
{
  "success": false,
  "message": "Descripcion del error",
  "errors": {}
}
```

## Autenticacion

### `POST /auth/register`

Request:

```json
{
  "fullName": "Nombre del usuario",
  "email": "usuario@example.com",
  "password": "123456"
}
```

Response `201`:

```json
{
  "success": true,
  "message": "User created",
  "data": {
    "token": "jwt-token",
    "user": {
      "id": "user-id",
      "fullName": "Nombre del usuario",
      "email": "usuario@example.com"
    }
  }
}
```

> El objeto `user` ya no incluye ningún campo de rol: la app no
> distingue cuentas de administrador, todas las cuentas autenticadas
> son pasajeros con exactamente las mismas pantallas y permisos.

### `POST /auth/login`

Request:

```json
{
  "email": "demo@royalairlines.com",
  "password": "Demo2026!"
}
```

Response `200`: misma estructura de registro.

### `GET /auth/me`

Devuelve el usuario autenticado. Requiere token.

### `PUT /auth/me`

Actualiza el nombre y correo del usuario autenticado. Requiere token.

Request:

```json
{
  "fullName": "Nombre actualizado",
  "email": "usuario@example.com"
}
```

### `POST /auth/change-password`

Cambia la contraseña del usuario autenticado. Requiere token.

Request:

```json
{
  "currentPassword": "123456",
  "newPassword": "654321"
}
```

## Home

### `GET /airports`

Response `data`:

```json
[
  {
    "code": "BOG",
    "city": "Bogota",
    "country": "Colombia",
    "airportName": "El Dorado"
  }
]
```

### `GET /promotions`

Response `data`:

```json
[
  {
    "id": "promo_001",
    "title": "Cartagena desde",
    "subtitle": "Fin de semana con tarifas especiales",
    "discountLabel": "Desde COP 245000",
    "origin": "BOG",
    "destination": "CTG",
    "active": true
  }
]
```

### `GET /destinations`

Devuelve destinos populares usando el mismo formato de aeropuerto.

## Vuelos

### `GET /flights/search`

Query parameters:

`origin=BOG&destination=CTG&departureDate=2026-09-01&returnDate=2026-09-05&passengers=2`

Cada vuelo debe incluir `id`, `airline`, `flightNumber`, `aircraft`,
`origin`, `destination`, `departureTime`, `arrivalTime`, `stops` y `fares`.
Cada tarifa incluye `travelClass`, `tierName`, `price`, `seatsAvailable` y
`benefits`.

### `GET /flights/{flightId}`

Devuelve el detalle de un vuelo y sus tarifas disponibles.

## Reservas y pago simulado

### `POST /bookings`

Request:

```json
{
  "flightId": "FL_1001",
  "passengers": [
    {
      "fullName": "Nombre del pasajero",
      "documentNumber": "12345678",
      "birthDate": "1995-06-15"
    }
  ],
  "fareType": "economy",
  "seats": ["12A", "12B"]
}
```

Response `201`:

```json
{
  "success": true,
  "data": {
    "bookingId": "BK_1001",
    "status": "pending_payment",
    "totalPrice": 520000
  }
}
```

### `POST /payments/confirm`

Es un pago simulado para la presentacion. Nunca se debe guardar el numero
completo ni el CVV.

**Importante:** el campo del monto se llama `amount` (no `totalPrice`),
para diferenciarlo del `totalPrice` que sí usa `POST /bookings`. Son dos
endpoints distintos con nombres de campo distintos a propósito.

Request:

```json
{
  "bookingId": "BK_1001",
  "paymentMethod": "card",
  "cardHolderName": "Titular de la tarjeta",
  "cardLastFour": "4242",
  "expiry": "12/29",
  "amount": 520000,
  "currency": "COP"
}
```

Response aprobada:

```json
{
  "success": true,
  "data": {
    "paymentId": "PAY_1001",
    "status": "approved",
    "reservationId": "RSV_1001",
    "confirmationCode": "ROYAL7A2"
  }
}
```

### `GET /reservations`

Lista las reservas del usuario autenticado, identificado por el token
(`Authorization`) — **no** recibe `userId` como query param. Puede
aceptar `status` como filtro opcional.

### `GET /reservations/{reservationId}`

Devuelve el detalle de una reserva confirmada.

### `GET /insights/community` (pendiente de definir con el equipo)

**Es la unica parte remota del modulo "Tu Perfil de Viajero".** El
arquetipo del usuario (Cazador de Ofertas, Explorador, Viajero Frecuente,
etc.) se calcula 100% localmente en Flutter con un algoritmo de
clustering (nearest-centroid) sobre el historial de reservas que YA vive
en memoria tras el login — no necesita red ni backend. Esta ruta solo
sirve para la SEGUNDA parte de la pantalla: comparar al usuario contra el
resto de la comunidad, dato que Flutter no puede calcular por si solo
porque requiere agregados de todos los usuarios.

No existen cuentas de administrador ni una vista distinta por rol —
cualquier cuenta autenticada consulta esta misma ruta y recibe la misma
comparacion agregada (promedios globales, no datos de otros usuarios en
particular).

Resumen de mineria de datos que Spring Boot arma consultando internamente
al servicio de Python **bajo demanda** (no corre 24/7, se calcula solo
cuando se solicita). Flutter nunca llama a Python directamente, solo
consume esta ruta del backend principal. Exige el header de autorizacion
con el token del usuario.

El formato exacto de campos aun no esta confirmado con el equipo de
Python/Spring Boot; el siguiente JSON es un ejemplo de referencia usado hoy
como mock en Flutter (ver
`lib/features/traveler_profile/repository/traveler_profile_repository.dart`):

- `averageTripsPerUser`: promedio de viajes por usuario en toda la
  comunidad, para comparar contra `totalTrips` del usuario actual.
- `tripsPercentile`: percentil (0.0 a 1.0) en el que queda el usuario
  actual respecto al resto de viajeros.
- `trendingDestinationCity`: ciudad destino que mas esta creciendo en
  reservas dentro de la comunidad esta temporada.

```json
{
  "success": true,
  "data": {
    "averageTripsPerUser": 3.4,
    "tripsPercentile": 0.72,
    "trendingDestinationCity": "Cartagena"
  }
}
```

Cuando el equipo confirme el modelo real (agregados desde base de datos,
calculo periodico en Python, etc.), actualizar este contrato y el parser
en `lib/models/traveler_profile_model.dart` (clase `CommunityInsights`).

## Orden de implementacion recomendado

1. Auth: register, login y me.
2. Airports, promotions y destinations.
3. Flights search y flight detail.
4. Bookings.
5. Payment confirm simulado.
6. Reservations y reservation detail.
7. Insights de comunidad (una vez Python/Spring Boot definan el calculo agregado real).

Cuando backend entregue estas respuestas, Flutter puede cambiar `useMockApi` a
`false` y actualizar `apiBaseUrl`; la estructura de pantallas y servicios no
deberia necesitar cambios.
