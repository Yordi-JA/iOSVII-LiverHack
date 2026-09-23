# Pulso · LiverHack 2026

Plataforma de atracción de talento para El Puerto de Liverpool: flujo de 6 etapas con semáforo de SLA,
pipeline visual de candidatos filtrados por AIRA, feedback por etapa y dashboard de RH.

## Correr la demo

```bash
flutter pub get
flutter run -d chrome
```

La demo usa datos locales (`MockTalentRepository`), no necesita Firebase para verse.

## Arquitectura

```
lib/
├── main.dart                     Punto de entrada (ProviderScope)
├── backend/                      Capa de datos
│   ├── models/                   Candidate, Vacancy, AppAlert, Person, PipelineStage
│   ├── repositories/             TalentRepository (interfaz) + Mock + Firestore
│   ├── seed/                     10 candidatos, 4 vacantes, alertas, directorio + seeder
│   └── providers.dart            Providers de Riverpod
└── frontend/                     Interfaz
    ├── app/
    │   ├── app.dart              MaterialApp.router + tema
    │   └── router.dart           Rutas (go_router) dentro del AppShell
    ├── core/                     Código compartido, sin lógica de negocio
    │   ├── theme/                Colores Liverpool, tipografía estilo Apple, ThemeData
    │   ├── widgets/              GlassCard, LiquidBackground, GradientAvatar, StatusPill...
    │   ├── layout/               AppShell, SideNav, TopBar
    │   └── utils/                Formateo de dinero e iniciales
    └── features/                 Un módulo por pantalla
        ├── dashboard/            Dashboard de RH (métricas + tarjetas)
        ├── procesos/             Flujo de 6 pasos + carril por postulante + popup
        ├── candidate_profile/    Perfil del postulante por secciones (proceso, perfil,
        │                         evaluación, compensación, contacto)
        ├── comparativa/          Top 10 por potencial HCAI + comparativa lado a lado
        ├── session/              Rol activo (Reclutador / HM / HRBP)
        └── shared/               Páginas de módulos en construcción
```

- **Frontend:** Flutter (web) con Riverpod para estado y go_router para navegación.
- **Backend:** Firebase: Cloud Firestore (datos en tiempo real), Storage (CVs en PDF), Hosting.

## Publicar en GitHub Pages

1. Sube el proyecto a un repositorio de GitHub (rama `main`).
2. En el repo: Settings → Pages → Source: **GitHub Actions**.
3. Cada push a `main` ejecuta `.github/workflows/deploy.yml` y publica en
   `https://<usuario>.github.io/<repo>/`.

La app usa rutas con `#` (`/#/procesos`), así que recargar cualquier pantalla funciona en Pages sin configuración extra.

## Conectar Firebase

1. Instala la CLI: `dart pub global activate flutterfire_cli`
2. En la carpeta del proyecto: `flutterfire configure` (crea `lib/firebase_options.dart`).
3. En `lib/main.dart`, descomenta la inicialización de Firebase y el override a `FirestoreTalentRepository`.
4. Llama una vez a `seedFirestore(FirebaseFirestore.instance)` para cargar los datos de prueba.

## Colecciones de Firestore

| Colección    | Contenido                                                        |
|--------------|------------------------------------------------------------------|
| `candidatos` | Datos del CV, AssessFirst, etapa, puntaje AIRA, feedback por etapa |
| `vacantes`   | Nivel, responsables, banda salarial, días reales vs SLA por etapa |
| `alertas`    | SLA, feedback pendiente, compensación, agenda                    |
| `users`      | Directorio de reclutadores, HMs, HRBPs y entrevistadores         |
| `eventos`    | Bitácora de trazabilidad (cambios de etapa)                      |
