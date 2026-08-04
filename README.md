# Lumière & Co. — PyME-Sync

Aplicación móvil/web para la gestión de una PyME de velas artesanales: catálogo e inventario de productos, control de usuarios y reportes, construida en Flutter con Firebase como backend.

**Demo en vivo:** https://moviles-tin-2026.github.io/pwa-equipopyme-03/

## Stack

- **Flutter** (web, con soporte Android) — UI, navegación y lógica de negocio.
- **Firebase Auth** — autenticación por correo y contraseña.
- **Cloud Firestore** — persistencia de productos y usuarios en tiempo real (`StreamBuilder`).
- **Firebase Storage** — almacenamiento de imágenes de producto.

## Estructura

El código de la app vive en [lumiere-app/mi_app](lumiere-app/mi_app):

```
lumiere-app/mi_app/lib/
├── main.dart          # Login y arranque de la app
├── inventario.dart    # Shell de navegación + catálogo/CRUD de productos
├── usuarios.dart       # Gestión de usuarios
├── reportes.dart       # Dashboard de KPIs y reportes
└── firebase_options.dart
```

El contenido en la raíz del repositorio (`index.html`, `main.dart.js`, `canvaskit/`, etc.) es el build de producción (`flutter build web`) publicado vía GitHub Pages. Se regenera con:

```bash
cd lumiere-app/mi_app
flutter build web --release --base-href /pwa-equipopyme-03/
# copiar el contenido de build/web/ a la raíz del repo
```

## Correr en local

```bash
cd lumiere-app/mi_app
flutter pub get
flutter run -d chrome     # o -d <dispositivo> para Android
```

## Tests y análisis estático

```bash
cd lumiere-app/mi_app
flutter analyze
flutter test
```

## Estado conocido / próximos pasos

- El módulo de "Usuarios" gestiona registros en Firestore pero aún no crea cuentas reales de Firebase Auth ni aplica permisos por rol.
- El historial de ventas en Reportes usa datos de ejemplo; falta una colección `ventas` real conectada al inventario.
- No hay reglas de seguridad (`firestore.rules` / `storage.rules`) versionadas todavía.
