<div align="center">

# 🏰 Turisgal App

<p>
  <b>Aplicación Integral de Gestión Turística y Check-in Digital</b>
</p>

<p>
  <a href="#-características">Características</a> •
  <a href="#-tecnologías">Tecnologías</a> •
  <a href="#-instalación">Instalación</a> •
  <a href="#-api-endpoints">API</a>
</p>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

</div>

---

## 📋 Descripción del Proyecto

**Turisgal** es una solución móvil desarrollada en **Flutter** para la gestión de alojamientos turísticos, permitiendo a los usuarios gestionar sus reservas y realizar procesos de check-in digital avanzados (OCR y firma). El sistema está respaldado por una API RESTful robusta construida con **Node.js**, **Express** y **Prisma**.

## 📱 Características Principales

### Módulo Móvil (Frontend)
- **Autenticación Segura:** Login, Registro, Recuperación de contraseña y Gestión de perfil (`auth_service.dart`).
- **Check-in Digital Avanzado:**
  - 📷 **OCR:** Escaneo y validación de documentos de identidad (`identity_verification_page.dart`).
  - ✍️ **Firma Digital:** Captura de firma manuscrita en pantalla (`signature_page.dart`).
  - 🔍 **Escáner QR:** Validación rápida de reservas (`mobile_scanner`).
- **Gestión de Reservas:** Visualización de reservas activas, pasadas y detalles de la propiedad (`my_reservation_screen.dart`).
- **Check-out:** Reporte de salida con evidencia fotográfica de incidencias (`check-out.dart`).
- **Geolocalización:** Mapas interactivos con OpenStreetMap (`flutter_map`).

### Módulo Servidor (Backend)
- **API REST:** Estructura modular con controladores y rutas separadas (`server.js`).
- **ORM Prisma:** Gestión de base de datos PostgreSQL con modelos relacionales (`User`, `Reservation`, `Checkin`).
- **Procesamiento de Imágenes:** Integración con `tesseract.js` para extracción de datos de DNI/Pasaportes.
- **Seguridad:** Autenticación JWT y hash de contraseñas con Bcrypt.

---

## 🛠 Tecnologías (Tech Stack)

### 📱 Cliente (Mobile)
* **Framework:** Flutter SDK ^3.9.2
* **Lenguaje:** Dart
* **Estado:** Provider
* **Mapas:** `flutter_map` & `latlong2`
* **Almacenamiento:** `flutter_secure_storage`, `shared_preferences`

### 🖥️ Servidor (Backend)
* **Runtime:** Node.js
* **Framework:** Express.js
* **Base de Datos:** PostgreSQL
* **ORM:** Prisma Client
* **OCR:** Tesseract.js

---

## 🚀 Guía de Instalación

Sigue estos pasos para desplegar el entorno de desarrollo localmente.

### 1. Configuración del Backend

Navega a la carpeta del servidor:

```bash
cd turigal-backend
```

Instala las dependencias y genera el cliente de Prisma:

```bash
npm install
npx prisma generate
```

Configura las variables de entorno creando un archivo `.env` en `turigal-backend/` (ejemplo):

```env
PORT=3000
DATABASE_URL="postgresql://user:password@localhost:5432/turisgal_db"
JWT_SECRET="tusecreto"
```

Ejecuta las migraciones y lanza el servidor:

```bash
npx prisma migrate dev --name init
npm run start:dev
```

### 2. Configuración de la App Móvil

Vuelve a la raíz del proyecto e instala dependencias de Flutter:

```bash
cd ..
flutter pub get
```

Configura la IP de tu API en `lib/services/api_service.dart`.
* **Emulador:** `http://10.0.2.2:3000/api`
* **Dispositivo Físico:** `http://TU_IP_LOCAL:3000/api`

Ejecuta la aplicación:

```bash
flutter run
```

---

## 📂 Estructura de Directorios

```text
turisgal-app/
├── lib/
│   ├── main.dart             # Entry point y Rutas
│   ├── services/             # Lógica de negocio (Auth, API)
│   ├── widgets/              # Componentes UI (Inputs, Scanner)
│   └── ...                   # Pantallas (Login, Home, Checkin)
│
├── turigal-backend/
│   ├── prisma/
│   │   └── schema.prisma     # Definición de la BD
│   ├── controllers/          # Lógica de endpoints
│   ├── routes/               # Definición de rutas API
│   └── server.js             # Configuración del servidor
```

---

## 📡 API Endpoints

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| **POST** | `/api/auth/login` | Iniciar sesión (Devuelve JWT) |
| **POST** | `/api/checkin/validate` | Validar código de reserva |
| **POST** | `/api/checkin/ocr` | Subir DNI para extracción de datos |
| **GET** | `/api/reservations` | Listar reservas del usuario |
| **POST** | `/api/checkout` | Finalizar estancia y subir fotos |

---

<br>
