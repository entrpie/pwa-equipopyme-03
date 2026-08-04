# Lumière & Co. — PyME-Sync

Aplicación móvil/web para la gestión de una PyME de velas artesanales: catálogo e inventario de productos, ventas, usuarios con roles y reportes, construida en Flutter con Firebase como backend.

**Demo en vivo:** https://moviles-tin-2026.github.io/pwa-equipopyme-03/

## Stack

- **Flutter** (web, con soporte Android) — UI, navegación y lógica de negocio.
- **Firebase Auth** — autenticación por correo y contraseña. Los usuarios nuevos se crean con una cuenta de Auth real desde el panel de Usuarios (ver `usuarios.dart`).
- **Cloud Firestore** — persistencia de productos, usuarios y ventas en tiempo real (`StreamBuilder`), protegida con reglas de seguridad basadas en rol (`firestore.rules`).
- **Firebase Storage** — almacenamiento de imágenes de producto, protegido con `storage.rules`.

## Estructura

El código de la app vive en [lumiere-app/mi_app](lumiere-app/mi_app):

```
lumiere-app/mi_app/lib/
├── main.dart          # Login y arranque de la app
├── inventario.dart    # Shell de navegación + catálogo/CRUD de productos
├── usuarios.dart       # Gestión de usuarios, cuentas de Auth y roles (RolService)
├── ventas.dart         # Registro de ventas (descuenta stock vía transacción)
├── reportes.dart       # Dashboard de KPIs, gráfica e historial (datos reales de `ventas`)
└── firebase_options.dart

lumiere-app/mi_app/
├── firestore.rules     # Reglas de acceso por rol para Firestore
└── storage.rules        # Reglas de acceso para Storage
```

### Roles

El rol de cada usuario se guarda en su documento de `usuarios` (mismo ID que su UID de Auth) y se consulta con `RolService.obtenerRolActual()`. Solo el rol **Administrador** puede: crear/eliminar usuarios y eliminar productos. Cualquier usuario autenticado puede: consultar catálogo, registrar ventas y ver reportes.

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

## Desplegar reglas de seguridad

Las reglas viven en el repo pero deben publicarse por separado con Firebase CLI (requiere acceso al proyecto `fir-login-b0a01`):

```bash
cd lumiere-app/mi_app
firebase deploy --only firestore:rules,storage:rules
```

## Estado conocido / próximos pasos

- Eliminar un usuario borra su acceso a nivel de la app (documento en Firestore), pero no su cuenta de Firebase Auth: eso requeriría Admin SDK desde un backend (p. ej. Cloud Functions), fuera del alcance de una app 100% cliente.
- El filtro temporal de Reportes ("Esta Semana" / "Este Mes" / "Este Año") todavía no filtra los datos mostrados.
