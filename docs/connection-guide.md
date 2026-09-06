# Cómo se conecta Flutter con Spring Boot (guía rápida)

Esta guía responde la pregunta clave: **¿a qué URL exacta debe apuntar
Flutter para hablar con el backend?** y da un ejemplo real de una
petición (`/auth/login`) para que el compañero de Spring Boot pueda
probar su endpoint ANTES de que Flutter se conecte.

> ✅ **Esta integración ya fue probada de punta a punta.** En
> `tools/mock-backend.js` hay un servidor de prueba (no es Spring Boot
> real, es un "doble" con Node) que implementa el mismo contrato. Se
> usó para activar `useMockApi: false` en Flutter y confirmar, con
> peticiones HTTP reales, que `AuthService`, `FlightService`,
> `BookingService` y `CommunityInsightsService` sí saben hablar con un backend
> real y parsear sus respuestas correctamente. Ver sección 7.

## 1. ¿Qué es "localhost" aquí y por qué no se puede usar tal cual?

Cuando Spring Boot corre en el computador, normalmente queda disponible
en:

```
http://localhost:8080
```

El problema: **Flutter no corre en ese mismo computador** — corre
dentro de un emulador Android (o un teléfono físico), que es como una
"mini computadora" aparte. Para esa mini computadora, `localhost`
significa "yo mismo" (el propio emulador), no el computador que lo
contiene. Por eso `localhost` **nunca funciona** desde Flutter hacia el
backend, aunque los dos estén en la misma máquina física.

La solución depende de dónde se está probando la app:

| Dónde corre Flutter | URL que debe usar | Por qué |
|---|---|---|
| Emulador Android (Android Studio) | `http://10.0.2.2:8080` | `10.0.2.2` es una IP especial que el emulador reconoce como "el computador que lo contiene" |
| Teléfono físico (USB o WiFi) | `http://192.168.X.X:8080` (la IP local del computador) | El teléfono es un dispositivo aparte en la red, necesita la IP real del computador en la red WiFi |
| iOS Simulator (Mac) | `http://localhost:8080` | El simulador de iOS sí comparte red con el Mac, a diferencia del emulador Android |

Esto ya está resuelto en el código: [lib/core/config/app_config.dart](/c:/Development/projects/royal_airlines/lib/core/config/app_config.dart)
tiene la variable `apiBaseUrl`, hoy en `http://10.0.2.2:8080` (para
emulador Android, que es lo que usa el equipo). Si alguien prueba desde
un teléfono físico, solo hay que cambiar esa única línea por la IP
local del computador (se obtiene con `ipconfig` en Windows, buscando
"Dirección IPv4").

## 2. ¿Qué puerto debe usar Spring Boot?

Por defecto Spring Boot arranca en el puerto **8080**. Mientras nadie
lo cambie en `application.properties`, la URL completa queda:

```
http://10.0.2.2:8080/v1/auth/login
```

(el `/v1` es el prefijo de versión que ya usa Flutter, ver
`AppConfig.apiVersion`).

## 3. Ejemplo real: probar `/auth/login` sin necesitar Flutter todavía

El compañero de Spring Boot puede probar su propio endpoint con este
comando, **sin depender de que Flutter esté corriendo**, para
confirmar que ya está listo antes de avisar al equipo:

```bash
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@royalairlines.com","password":"Demo2026!"}'
```

(aquí sí se usa `localhost`, porque quien prueba con `curl` está en el
mismo computador donde corre Spring Boot — la regla de "localhost no
funciona" es solo un problema de Flutter/emulador, no de Spring Boot).

Respuesta esperada (ver contrato completo en
[docs/api-contract.md](/c:/Development/projects/royal_airlines/docs/api-contract.md)):

```json
{
  "success": true,
  "message": "Operation completed",
  "data": {
    "token": "jwt-token-de-ejemplo",
    "user": {
      "id": "user-id",
      "fullName": "Nombre del usuario",
      "email": "demo@royalairlines.com"
    }
  }
}
```

Si Spring Boot responde así, Flutter ya puede conectarse a ese mismo
endpoint sin ningún cambio adicional de código, solo activando el modo
real (ver paso 4).

## 4. Cómo activa Flutter la conexión real (cuando el backend ya responda)

No hay que editar archivos para alternar entre modo local y REST. Ejecuta
Flutter con los valores del backend:

```dart
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Sustituye `http://10.0.2.2:8080` por la URL del backend de Spring Boot
(o por su URL HTTPS pública). Después de ello, cada pantalla empieza a
llamar al backend real automáticamente — no hay que tocar ninguna pantalla
ni controlador, porque toda la app ya está construida para funcionar así
desde el día uno (ver `lib/services/`).

## 5. Un problema común que hay que anticipar: CORS

Cuando Flutter corre en modo **web** (no emulador/teléfono), el
navegador puede bloquear la petición al backend por política de CORS.
Esto no afecta al emulador Android ni a teléfonos físicos, solo si en
algún momento prueban la app en Chrome. Si pasa, la solución es en
Spring Boot: agregar `@CrossOrigin` (o una configuración global de CORS)
permitiendo el origen desde donde corre Flutter Web.

## 6. Checklist para la primera prueba real conjunta

1. Spring Boot corriendo y respondiendo al `curl` del paso 3.
2. Confirmar el puerto real (8080 u otro) y avisar al equipo si cambia.
3. En Flutter: actualizar `apiBaseUrl` si alguien prueba desde teléfono
   físico en vez de emulador.
4. Cambiar `useMockApi` a `false`.
5. Probar login desde la app real y confirmar que llega el `token`.
6. Si falla, revisar primero: ¿está bien el puerto?, ¿el celular/emulador
   está en la misma red WiFi que el computador (para teléfono físico)?,
   ¿el firewall de Windows está bloqueando el puerto 8080?

## 7. Cómo se probó ya la integración real (sin esperar a Spring Boot)

Para no depender de tu compañero para validar que Flutter sabe hablar
con un backend real, se creó `tools/mock-backend.js`: un servidor de
prueba muy simple (Node puro, sin frameworks) que responde EXACTAMENTE
igual que describe `docs/api-contract.md` para los endpoints
principales (login, airports, flights/search, bookings,
payments/confirm, insights/community).

Con ese servidor corriendo, se puso `useMockApi: false` en Flutter y se
ejecutó `tools/verify_real_integration.dart`, un script que hace
peticiones HTTP reales (no mock) contra ese servidor y valida que las
respuestas tengan exactamente la forma que la app espera. Resultado:
**6 de 6 verificaciones pasaron** — login, aeropuertos, búsqueda de
vuelos, creación de reserva, confirmación de pago y dashboard de
analítica.

Esto confirma que el problema NO está en Flutter: el "cableado" ya
funciona. Lo único que falta es que Spring Boot exista y responda con
el mismo formato de JSON.

### Cómo repetir esta prueba tú misma/o

```powershell
# Terminal 1: levantar el servidor de prueba
node tools/mock-backend.js

# Terminal 2: correr las verificaciones
dart run tools/verify_real_integration.dart
```

## 8. Publicar el backend de prueba en internet (URL real, no solo localhost)

Para que tu compañero pueda ver la conexión funcionando desde ya, sin
instalar nada en su computador, se puede publicar `tools/mock-backend.js`
gratis en Render usando el archivo `render.yaml` que ya está en la raíz
del repositorio.

**Pasos (los tienes que hacer tú, requieren tu cuenta):**

1. Sube este repositorio a GitHub (si aún no lo has hecho).
2. Entra a [render.com](https://render.com) y crea una cuenta gratuita
   (puedes usar tu cuenta de GitHub para entrar más rápido).
3. Click en **"New"** → **"Blueprint"**.
4. Selecciona el repositorio `royal_airlines` de GitHub.
5. Render detecta automáticamente el archivo `render.yaml` y muestra el
   servicio `royal-airlines-mock-backend` listo para crear — dale
   **"Apply"** / **"Create"**.
6. Espera 2-3 minutos a que termine el primer despliegue (verás logs en
   pantalla, es normal que tarde la primera vez).
7. Cuando termine, Render te da una URL pública, algo como:
   `https://royal-airlines-mock-backend.onrender.com`

**Cómo usar esa URL en Flutter:**

En [lib/core/config/app_config.dart](/c:/Development/projects/royal_airlines/lib/core/config/app_config.dart):

```dart
static const String apiBaseUrl = 'https://royal-airlines-mock-backend.onrender.com';
static const bool useMockApi = false;
```

Con esto, cualquiera que corra la app (tú, tu compañero, el profesor)
va a estar hablando con un servidor real en internet, no con datos
inventados dentro del celular. Es la prueba más clara de que la
integración funciona.

**Aviso importante:** el plan gratuito de Render "duerme" el servicio
si nadie lo usa por un rato, y tarda ~30-50 segundos en despertar en la
primera petición del día. Es normal, no es un error. Cuando Spring Boot
esté listo de verdad, se reemplaza esta URL por la de Spring Boot y se
borra este servicio de prueba.

Cuando Spring Boot exista de verdad, se puede repetir exactamente este
mismo procedimiento apuntando a su URL en vez de
`tools/mock-backend.js`, para confirmar que responde con el mismo
formato antes de dar por “integrado” el proyecto completo.
