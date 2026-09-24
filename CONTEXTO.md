# Contexto maestro: Puerta Liverpool (LiverHack 2026)

> Documento para que otra IA retome el proyecto sin el historial de conversación. Describe qué es, cómo está construido, qué hace hoy, qué falta y qué se ha hecho (sección 7), incluidas las decisiones del usuario que no deben revertirse.

## 1. Descripción global

**Puerta Liverpool** es un prototipo web de atracción de talento para El Puerto de Liverpool, creado para el hackathon **LiverHack 2026**. No sustituye al sistema principal de reclutamiento (ATS). Es una capa colaborativa que conecta a Atracción de Talento (AT, "Reclutador"), Hiring Managers (HM) y HRBP, con foco en visibilidad, acuerdos de nivel de servicio (SLA) y decisiones rápidas.

La app es un único **módulo de Candidatos**, que es la pantalla inicial y la única accesible desde la interfaz. Funcionalidad:

- **Login simulado por roles:** un menú desplegable en la barra superior (Reclutador / Hiring manager / HRBP) cambia vacantes visibles, columnas, avisos, pestañas y permisos sin recargar.
- **Datos:** 11 vacantes y 34 candidatos desde `assets/seed_data_liverhack.json`.
  - 28 candidatos están importados.
  - 6 (ids 29–34, de VAC-110 y VAC-111) siguen "en el ATS" (`"importado": false`) hasta que Reclutamiento los importa.
- **Flujo de 6 etapas por vacante:** Requisición → Alineación → Búsqueda → Atracción → Selección → Oferta. Los días permitidos por etapa dependen de la complejidad de la vacante.
- **Cada etapa avanza por una acción de negocio del rol responsable:**
  1. **Requisición (HRBP):** "Validar posición y aprobar presupuesto" → Alineación.
  2. **Alineación (HM):**
     - "Editar Perfil / Negociar" abre un formulario con presupuesto y no negociables.
     - "Aprobar Alineación" → Búsqueda (arranca el SLA).
  3. **Búsqueda (Reclutador):** "Importar candidatos desde ATS (Aira)" simula 1 s de carga, llena la tabla y pasa sola a Atracción.
  4. **Atracción (Reclutador):** marca casillas y usa "Mover seleccionados a Entrevista con HM"; con el primer candidato movido, la vacante pasa sola a Selección.
  5. **Selección (HM):**
     - "Marcar finalista" o "Descartar" (justificación de 20+ caracteres) registran decisiones y la vacante sigue en la etapa 5.
     - "Seleccionar para Oferta" (botón azul) elige al ganador: los demás activos se descartan automáticamente con correo y la vacante pasa a la etapa 6. La ficha del finalista muestra el recuadro "Siguiente paso: oferta final".
  6. **Oferta (HRBP):** recibe la alerta 💰 y usa "Aprobar Presupuesto" en la tarjeta "Oferta final" → "Trámites de contratación iniciados".
  - En cada etapa, los roles que no actúan ven a quién se está esperando.
- **SLA del HM:** candidatos enviados al HM sin veredicto: ámbar a los 3–4 días y rojo a partir de 5. Se ve en la campana, los badges del desplegable de vacantes, los avisos y los KPIs.
- **Ficha del candidato (acordeón en la tabla):**
  - Hub de comunicación Workspace.
  - Resumen profesional, compensación, formación e idiomas.
  - AssessFirst con sus 6 campos, historial de entrevistas y visor de CV.
  - Acciones según el rol.
- **Comparativa** de 2 a 4 candidatos: tabla con la estructura del Excel de los organizadores o radar de 6 ejes.
- **Vista Resumen** (solo AT y HRBP): KPIs globales, estado de todas las vacantes, dispersión fit contra costo y veredictos pendientes por HM.
- **Hub de Workspace (simulado):**
  - Chat, Meet y Drive abren hojas inferiores con estilo Material 3 / Google.
  - Gmail (solo Reclutador) abre la ventana "Mensaje nuevo" con templates.
  - Al descartar a un candidato aparece un SnackBar oscuro: "Candidato descartado. Correo automático de retroalimentación enviado vía Gmail."
- **Campana de alertas por rol (RBAC):** notificaciones calculadas con el estado real. Al tocar una, se abre la vacante o la ficha relacionada.
- **Lienzo colaborativo de entrevistas (Firebase):** en la etapa 5 (Selección), la ficha de cada candidato tiene un lienzo de notas que Reclutamiento y el HM editan al mismo tiempo. Las notas se sincronizan en tiempo real con Cloud Firestore (`entrevistas/candidato_{id}`). Es el único módulo que usa Firebase; si no está configurado, funciona en modo local.
- **Máquina del tiempo:** al tocar una etapa completada del flujo, toda la pantalla se ve como estaba al cerrar esa etapa, en solo lectura y sin datos del futuro. Se regresa tocando la etapa actual.
- **Persistencia local:** rol, vacante activa, etapas, perfil negociado, importaciones, envíos, decisiones, oferta y bitácora sobreviven a una recarga (`shared_preferences`).

**Datos generales:**

- **Nombre y código:** paquete Dart `puerta_liverpool` (antes `pulso`); clase raíz `PuertaLiverpoolApp`.
- **Idioma:** español de México. Moneda: MXN.
- **Repositorio:** `https://github.com/Yordi-JA/iOSVII-LiverHack`, rama `main`.
- **Especificaciones de origen**, fuera del repo:
  - `LiverHack.md` (contexto 1): visión, requisitos y las 6 etapas.
  - `contexto2.md` (contexto 2): especificación del módulo de Candidatos.

## 2. Árbol de directorios

Se omiten `.git/`, `.dart_tool/`, `build/`, `.idea/` y los archivos generados de `windows/`.

```
iOSVII-LiverHack/
├── .github/workflows/deploy.yml     CI: build web + deploy a GitHub Pages
├── analysis_options.yaml            flutter_lints; excluye build/, web/, windows/
├── pubspec.yaml / pubspec.lock      paquete puerta_liverpool
├── README.md
├── CONTEXTO.md                      este documento
├── assets/
│   ├── seed_data_liverhack.json     11 vacantes, 34 candidatos (6 aún en Aira)
│   ├── cvs/                         PDFs de CV (vacía: solo .gitkeep)
│   └── fotos/                       fotos del seed antiguo y del avatar del usuario
├── Perfiles_fotos/                  fotos sueltas (no declaradas como asset)
├── web/                             index.html y manifest.json con título "Puerta Liverpool"
├── windows/                         runner nativo (ventana "Puerta Liverpool")
├── test/                            38 tests (ver sección 6)
└── lib/
    ├── main.dart                    SharedPreferences + Firebase.initializeApp (try/catch) + ProviderScope
    ├── firebase_options.dart        generado por `flutterfire configure` (web, proyecto puerta-liverpool-2026)
    ├── backend/                     CAPA DE DATOS (candidatos/ no depende de la UI)
    │   ├── candidatos/
    │   │   ├── models.dart          LiverhackSeed, SlaConfig, Vacante, Candidato, EvaluacionAssessFirst,
    │   │   │                        Idioma, Entrevista, StatusProceso, Veredicto, Evento, TipoEvento, stages
    │   │   ├── rules.dart           SLA, presupuesto, días por etapa, visibilidad por rol, radar, tabulador
    │   │   └── seed_repository.dart loadLiverhackSeed() y LiverhackStore (persistencia)
    │   ├── entrevistas/
    │   │   └── entrevistas_repository.dart  EntrevistasRepository (Firestore y local), firebaseDisponibleProvider,
    │   │                                    entrevistasRepositoryProvider, notasEntrevistaProvider
    │   ├── models/, repositories/, seed/   seed y modelos antiguos (los usan solo módulos antiguos)
    │   └── providers.dart           providers antiguos + liverhackStoreProvider
    └── frontend/                    CAPA DE PRESENTACIÓN
        ├── app/
        │   ├── app.dart             PuertaLiverpoolApp: MaterialApp.router + tema
        │   └── router.dart          GoRouter: arranca en /candidatos; "/" redirige ahí
        ├── core/
        │   ├── layout/
        │   │   ├── app_shell.dart   fondo líquido + WorkspaceSnackHost + ToastHost + TopBar + contenido
        │   │   └── top_bar.dart     marca a la izquierda; a la derecha: menú de rol, campana y perfil
        │   ├── theme/               AppColors (incluye flowDone/flowCurrent), AppTypography (Montserrat), AppTheme
        │   ├── utils/formatters.dart formatMoney, formatMoneyShort ($1.25M), initialsOf
        │   └── widgets/             GlassCard, StatusPill, GradientButton (large), GlassSegmented,
        │                            GradientAvatar, LiquidBackground, ToastHost, charts…
        └── features/
            ├── candidatos/          MÓDULO ACTIVO
            │   ├── candidatos_controller.dart  CandidatosState, CandidatosNotifier, liverhackSeedProvider
            │   ├── candidatos_page.dart        encabezado + pestañas + vista; o TimeMachineView en el pasado
            │   └── widgets/
            │       ├── vacancy_picker.dart     desplegable de vacantes en el título + AlertBadge
            │       ├── vacancy_header.dart     selector, "Ver detalles" plegable, StageStepper tocable
            │       ├── stage_gate.dart         tarjetas de las etapas 1–3 (+ StageGate.historico, solo lectura)
            │       ├── oferta.dart             "Seleccionar para Oferta", diálogo, "Siguiente paso", tarjeta "Oferta final"
            │       ├── time_machine_view.dart  vista de una etapa pasada (solo lectura)
            │       ├── role_banners.dart       avisos por rol agrupados + KpiTile/KpiRow
            │       ├── candidate_table.dart    tabla con ficha en acordeón (modo instantánea de solo lectura)
            │       ├── candidate_detail.dart   ficha (modo solo lectura)
            │       ├── collaborative_canvas.dart  CollaborativeCanvas: lienzo de notas en tiempo real (debounce 500 ms)
            │       ├── assessfirst_card.dart, interview_timeline.dart, decision_box.dart
            │       ├── cv_viewer.dart + cv_frame_web.dart / cv_frame_stub.dart
            │       ├── comparison_view.dart    tabla estilo Excel y radar (fl_chart)
            │       ├── summary_view.dart       vista Resumen
            │       └── ui_kit.dart             pills, FitBar, CompatRing, VisionMeter, ToneButton, correoSimulado,
            │                                   fechaCorta, fechaRelativa
            ├── workspace/
            │   ├── workspace_style.dart        GColors, gText (Roboto), SnackBars estilo Google
            │   └── workspace_hub.dart          barra "Comunicación" + Chat, Meet, Drive y Gmail
            ├── notifications/role_alerts.dart  roleAlertsProvider (RBAC)
            ├── session/role_provider.dart      rol activo (persistido)
            ├── procesos/            módulo antiguo; su StageStepper es el flujo que usa Candidatos
            └── dashboard/, comparativa/, candidate_profile/, shared/   módulos antiguos, sin acceso desde la UI
```

## 3. Arquitectura y flujo

### Capas

| Capa | Ubicación | Responsabilidad |
|---|---|---|
| Entrada | `lib/main.dart` | Obtiene `SharedPreferences` (en try/catch), intenta `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` (en try/catch) y sobrescribe `liverhackStoreProvider` y `firebaseDisponibleProvider`. |
| Colaboración en tiempo real | `lib/backend/entrevistas/` | Único uso de Firestore: notas del lienzo de entrevistas. **No** reemplaza a `LiverhackStore`. |
| Dominio y reglas | `lib/backend/candidatos/` | Modelos inmutables con `fromJson`/`copyWith` y reglas puras. Las reglas devuelven un `Tone` (ok/warn/bad/mute), nunca colores. |
| Persistencia | `LiverhackStore` | Clave `lh26`. Guarda: rol, vacante activa, bitácora (`eventos`); por vacante, solo lo que difiere del seed (etapa, días en etapa, presupuesto, no negociables, `oferta_aprobada`); por candidato, estatus, justificación, `enviado_hm`, `dias_esperando_hm` e `importado`. |
| Estado | `candidatos_controller.dart` | `AsyncNotifier<CandidatosState>`: vacante activa, vista, ficha abierta, seleccionados, modo de comparativa, zoom, copias mutables de vacantes y candidatos (`todos`), bitácora y `etapaVista`. |
| Estado global de UI | `role_provider.dart`, `toast_host.dart`, `workspace_style.dart`, `role_alerts.dart` | Rol activo, toasts, SnackBars de Workspace y alertas por rol (con vistas y no vistas). |
| Presentación | `lib/frontend/` | Widgets que traducen `Tone` a colores de `AppColors`. |

### Flujo de datos

```
assets/seed_data_liverhack.json
   └─ liverhackSeedProvider (FutureProvider; los tests lo sobrescriben)
        └─ candidatosProvider (AsyncNotifier<CandidatosState>)
             ├─ al construir: LiverhackStore.applyVacanteOverrides / applyOverrides / eventos
             ├─ escucha currentRoleProvider → limpia selección y ficha (sin aviso)
             └─ acciones:
                  UI: selectVacante, toggleOpen, setView, setCmpMode, zoom, openFromAlert, verEtapa
                  negocio (bloqueadas en el pasado): togglePick (máx. 4), avanzarEtapaVacante,
                    editarPerfilVacante, importarDesdeAts (async), moverAEntrevistaHm / enviarAHm,
                    decidir, seleccionarFinalista, aprobarOferta
                  cada acción de negocio → _registrar(Evento) + LiverhackStore.save*

UI ← ref.watch(candidatosProvider) + ref.watch(currentRoleProvider)
TopBar (campana) ← roleAlertsProvider ← candidatosProvider + currentRoleProvider
```

### Getters clave de `CandidatosState`

| Getter | Qué devuelve |
|---|---|
| `candidatos` | Solo los importados (lo único que ve la UI). |
| `enAts(vacanteId)` | Los que siguen en Aira. |
| `vacante` | La vacante activa. |
| `vacanteDe(c)` | La vacante del candidato `c`. |
| `visibles(role)` | Candidatos visibles para el rol, por compatibilidad. |
| `vacantesVisibles(role)` | Vacantes visibles para el rol. |
| `alertas` / `alertasDe(id)` | Candidatos en alerta de SLA. |
| `picked` | Los seleccionados con las casillas. |
| `movibles` | Seleccionados en proceso y aún no enviados al HM. |
| `ofertaDe(vacanteId)` | El candidato en Oferta o, en vacantes que ya llegaron a la etapa 6 en el seed, su finalista. |
| `eventosDe(vacanteId, etapa)` | Eventos de esa etapa, del más reciente al más antiguo. |
| `viendoPasado` | `etapaVista` es una etapa anterior a la actual. |
| `vacanteEnEtapa(etapa)` | La vacante con el presupuesto y los no negociables previos a negociaciones posteriores (los toma de `Evento.datos`). |
| `candidatosEnEtapa(etapa, rol)` | La lista reconstruida (ver "Máquina del tiempo"). |

### Comportamientos importantes

- **Rol:** `UserRole.reclutador` = AT, `hiringManager` = HM, `hrbp` = HRBP. `entrevistador` existe en el enum, pero no está en el menú.
- **Toasts:** `ToastHost` muestra el último toast 3.8 s en una cápsula inferior; admite `**negritas**`. Cambiar de rol **no** muestra toast (el usuario pidió quitarlo).
- **SnackBars de Workspace:** el controlador publica en `workspaceSnackProvider` y `WorkspaceSnackHost` los muestra con fondo oscuro. Las hojas y los diálogos capturan el `ScaffoldMessenger` antes de cerrarse (`showWorkspaceSnackBarOn`).
- **Avance de etapa:**
  - `avanzarEtapaVacante` acepta solo un paso hacia adelante y reinicia `diasEnEtapa`.
  - Avances automáticos: `importarDesdeAts` (3 → 4, espera `atsDelay` = 1 s) y `moverAEntrevistaHm` (4 → 5; `enviarAHm` usa la misma lógica).
  - `seleccionarFinalista`: ganador a `StatusProceso.oferta`, el resto de los activos a Descartado con la justificación "Descarte automático: …", vacante a la etapa 6 y SnackBar con el número de correos.
  - `aprobarOferta` marca `ofertaAprobada`.
- **Negociación (`editarPerfilVacante`):** guarda el presupuesto y los no negociables (descarta líneas vacías) y registra un evento con los valores anteriores en `datos` (`presupuesto_antes`, `no_negociables_antes`).
- **Bitácora (`Evento`):**
  - Cada acción de negocio se registra con la etapa en la que ocurrió, el rol como actor, la hora, un texto y datos estructurados opcionales.
  - Tipos: aprobación, negociación, importación, envío, decisión, oferta y contratación.
  - Solo existe desde que se implementó: las etapas completadas antes no tienen eventos.
- **Máquina del tiempo:**
  - Tocar un círculo **pasado** del `StageStepper` fija `etapaVista`. Tocar la misma etapa, la actual o una futura la regresa a `null`. Cambiar de vacante o abrir una alerta también regresa al presente.
  - No hay banner ni botón "Volver al presente" (el usuario pidió quitarlos). Bajo el flujo aparece el texto "Toca la etapa actual para regresar al presente".
  - Con `viendoPasado`, `candidatos_page.dart` reemplaza pestañas y contenido por `TimeMachineView`:
    - **Encabezado:** en el pasado se oculta la pill "{etapa}: día X de Y", porque ese contador es del presente.
    - **Etapas 1–3:** `StageGate.historico`, la tarjeta de la etapa en solo lectura con el pie "Etapa completada" (quién y cuándo, según la bitácora). En la etapa 1 se muestra el presupuesto previo a la negociación. La etapa 3 muestra una tabla vacía con "Los candidatos aún estaban en el ATS (Aira) en esta etapa". No hay candidatos.
    - **Etapas 4–5:** KPIs y tabla reconstruidos. En Atracción, nadie enviado al HM y sin entrevistas ni decisiones. En Selección se deshace el cierre: Oferta vuelve a finalista y los descartes automáticos vuelven a "en proceso". Las casillas están deshabilitadas, sin botones de acción y con la pill "Solo lectura". La ficha muestra "Solo lectura · instantánea de la Etapa N", sin Workspace ni decisiones.
  - Toda acción de negocio llama a `_bloqueadoPorPasado()`: no hace nada y avisa "Toca la etapa actual en el flujo para hacer cambios".
- **Lienzo colaborativo (Firebase):**
  - `entrevistasRepositoryProvider` devuelve `FirestoreEntrevistasRepository(FirebaseFirestore.instance)` si `firebaseDisponibleProvider` es `true`; si no, `LocalEntrevistasRepository`, que guarda en memoria y no sincroniza entre equipos. En los tests queda en modo local salvo override.
  - Firestore: documento `entrevistas/candidato_{id}` con los campos `notas` (String), `candidato_id`, `autor` (rol que escribió) y `actualizado` (`serverTimestamp`). Se escribe con `set(…, merge: true)`.
  - `notasEntrevistaProvider` (`StreamProvider.family<String, int>`) escucha el documento en tiempo real.
  - `CollaborativeCanvas`:
    - `TextField` multilínea con Montserrat dentro de `GlassCard`.
    - **Debounce de 500 ms** en `onChanged` antes de llamar a `actualizarNotas`; si la ficha se cierra con cambios pendientes, se guardan igual.
    - Mientras hay cambios locales sin guardar no se aplica el texto remoto; cuando llega texto de la otra persona, se aplica conservando la posición del cursor.
    - Indicador arriba a la derecha: "🟢 Sincronizado en tiempo real" (Firestore conectado), "⏳ Conectando…", "🔴 Sin conexión con Firestore" o "🔴 No se pudo guardar en Firestore", y "⚪ Modo local (Firebase no configurado)" sin Firebase.
  - Se muestra en la ficha, debajo del historial de entrevistas, solo si la vacante está en la etapa 5 y la ficha no está en solo lectura (no aparece en la máquina del tiempo).
  - Es colaboración "el último en escribir gana" a nivel de documento: no hay edición carácter por carácter ni resolución de conflictos.
- **Campana (`roleAlertsProvider`):** se llama así porque `alertsProvider` ya existe para el seed antiguo. El badge rojo cuenta las no vistas; abrir el menú las marca como vistas (en memoria). Alertas por rol:
  - **HM:** "N candidatos esperan tu feedback hace más de 3 días (SLA en riesgo)" y "Alineación pendiente: …".
  - **Reclutador:** "El HM aprobó la alineación" (vacantes en Búsqueda), "Carlos Mendoza compartió un archivo en Drive" (la única alerta fija) y SLA de los HM.
  - **HRBP:** "💰 El HM ha seleccionado a X. Requiere tu aprobación de paquete de compensación (Expectativa: $Y)", "La requisición excede el tabulador, requiere aprobación" y finalistas por aprobar.

### Reglas de negocio (`rules.dart`)

- **SLA (`slaInfo`):** "Sin reloj" si no está en proceso, no se envió al HM o `dias_esperando_hm` es null. Si no: rojo con 5 días o más, ámbar con 3 o más y verde en otro caso.
- **Presupuesto (`budgetInfo`):** r = deseada / presupuesto. Con r ≤ 1, "Dentro de presupuesto"; con r ≤ 1.1, "Negociable (+x%)"; si no, "Excede x%".
- **Días por etapa (`stageDays`):** `max(1, round(base × multiplicador de complejidad))`. La etapa está vencida si `dias_en_etapa` supera ese valor.
- **Tabulador (`excedeTabulador`):** topes de demo por complejidad (Bajo $450k, Medio $800k, Alto $900k, Complejo $1.4M), porque el JSON no trae tabulador. Solo se evalúa en Requisición y Alineación.
- **Visibilidad por rol:**
  - El HM solo ve candidatos enviados, y vacantes con enviados o en Alineación. No ve compensación actual, presupuesto ni Resumen, salvo el presupuesto en la tarjeta de Alineación, porque lo negocia.
  - Solo el AT envía al HM, importa desde Aira y mueve a entrevista.
  - Solo el HM decide, negocia, aprueba la alineación y selecciona para oferta.
  - Solo el HRBP aprueba la requisición y la oferta.
  - En las etapas 1 a 3 la vista Candidatos muestra la tarjeta de la etapa (`StageGate`) en lugar de la lista.
- **Radar (0–10):**
  - Compatibilidad: puntaje entre 10.
  - Experiencia: años, acotados de 0.5 a 10.
  - Inglés: A1 = 1, A2 = 2, B1 = 4, B2 = 6, C1 = 8, C2 = 10 y Nativo = 10.
  - Liderazgo por estilo: Transformacional 9, Coach y Situacional 8, Participativo, Democrático y Servicial 7, Directivo 6, Colaborador individual 3, En desarrollo 2.
  - Visión: Alta 9, Media 6, Baja 3.
  - Presupuesto: `min(1, presupuesto / deseada) × 10`.

### Navegación (go_router)

- `ShellRoute` con `AppShell`. **No hay menú lateral.** La ruta inicial es `/candidatos`, y `/` redirige ahí.
- Siguen registradas, pero sin acceso desde la UI: `/procesos`, `/procesos/candidato/:id`, `/comparativa`, `/entrevistas`, `/directorio`, `/alertas`. El Dashboard no tiene ruta.
- Dentro del módulo se navega con:
  - el desplegable de vacantes, en el título;
  - las pestañas (Candidatos / Comparativa (n) / Resumen);
  - el flujo tocable (máquina del tiempo);
  - la campana.
- Las URLs usan hash (`/#/candidatos`), lo que las hace compatibles con GitHub Pages.

### Diseño

- **Barra superior (patrón Z):**
  - **Izquierda:** marca "Puerta **Liverpool**" (monograma "P" con el gradiente).
  - **Derecha**, en este orden y separados 24 px:
    - el **menú de rol**, un botón con solo el texto del rol activo, sin ícono ni flecha, que abre las 3 opciones;
    - la **campana**, con el ícono centrado en el círculo;
    - el **perfil**: avatar y "Hola, {nombre}". Con menos de 760 px de ancho, solo el avatar; con menos de 1000 px, la marca queda solo como monograma.
  - **Sin buscador.**
- **Paleta (`AppColors`):** morado `#6B2BD9`, magenta `#E10098` y naranja `#FF7A1A`, más tintas y estados.
- **Flujo de 6 etapas (`StageStepper` y mini barra de cada vacante):** completadas en morado `#702F8A` (`flowDone`) con ✓; la actual en rosa `#E10098` (`flowCurrent`) con un halo que "respira"; las pendientes en vidrio. En el encabezado, las etapas se pueden tocar.
- **Tipografía:** **Montserrat** vía `google_fonts`, tanto en `AppTypography._base` como en `montserratTextTheme` global. Excepción intencional: la simulación de Workspace usa Roboto y colores de Google (azul `#1A73E8`, rojo `#EA4335`, verde de Chat `#00796B`).
- **Estética "liquid glass":** `GlassCard` con `BackdropFilter`, fondo con manchas desenfocadas y cápsulas. Solo tema claro.
- **Carga visual reducida:**
  - vacantes en un desplegable, no en una barra lateral;
  - detalles de la vacante plegados en "Ver detalles";
  - avisos por rol agrupados en una línea ("+n avisos");
  - ficha en dos columnas desde 1100 px;
  - tablas con ancho mínimo y scroll horizontal.

### Patrones

- **Riverpod 3:** `Notifier`, `AsyncNotifier`, `FutureProvider` y `Provider`; los overrides sirven para inyección y tests.
- **Modelos:** inmutables con `copyWith`, con un centinela para campos que pueden volverse null.
- **Reglas:** puras, separadas de la UI y cubiertas por tests.
- **Import condicional** (`dart.library.js_interop`) para el iframe del visor de CV.
- **Menús y popovers:** `MenuAnchor` en el desplegable de vacantes (su lista usa `primary: false`); `PopupMenuButton` en el menú de rol y la campana.
- **Plegables:** `AnimatedSize` en la ficha en acordeón, "Ver detalles" y los avisos.

### Deuda conocida

- Los modelos antiguos (`backend/models/…`) importan `AppColors` del frontend; los de `backend/candidatos/` no.
- Conviven dos juegos de datos: el seed antiguo (módulos antiguos) y el JSON del módulo de Candidatos.
- El saludo de la barra superior usa nombres fijos por rol (`displayNameFor`), no los de la vacante activa.

## 4. Archivos clave

| Archivo | Responsabilidad |
|---|---|
| `lib/main.dart` | Arranque y override de `liverhackStoreProvider`. |
| `lib/frontend/app/router.dart` | Rutas; raíz en `/candidatos`. |
| `lib/frontend/core/layout/app_shell.dart` | Fondo, `WorkspaceSnackHost`, `ToastHost`, `TopBar` y contenido. |
| `lib/frontend/core/layout/top_bar.dart` | `_Brand`, `_RoleMenu` (PopupMenuButton), `_BellButton` (PopupMenuButton con alertas por rol) y `_Profile`. |
| `lib/backend/candidatos/models.dart` | Esquema del JSON. `StatusProceso`: En Proceso, Finalista, Oferta y Descartado. `Vacante.ofertaAprobada`. `Candidato.importado`. `Evento` con `datos`. |
| `lib/backend/candidatos/rules.dart` | Reglas de negocio (sección 3). |
| `lib/backend/candidatos/seed_repository.dart` | `loadLiverhackSeed()` y `LiverhackStore` (lectura y escritura en try/catch). |
| `lib/frontend/features/candidatos/candidatos_controller.dart` | Estado, acciones, bitácora, instantáneas y bloqueo del pasado. |
| `lib/frontend/features/candidatos/candidatos_page.dart` | Encabezado, pestañas y vista activa: lista (`StageGate` en las etapas 1–3; `OfertaCard` en la 6), Comparativa o Resumen; o `TimeMachineView`. |
| `widgets/vacancy_header.dart` | `VacancyPicker`, pill de días en etapa, "Ver detalles" y `StageStepper` tocable. |
| `widgets/stage_gate.dart` | Tarjetas de Requisición (HRBP), Alineación con diálogo de negociación (HM) y Búsqueda con importación (AT); tarjeta de espera para los demás roles; `StageGate.historico`. |
| `widgets/oferta.dart` | `SeleccionarOfertaButton` y su diálogo (justificación de 20+ caracteres), `SiguientePasoOferta` y `OfertaCard` (con "Aprobar Presupuesto" para el HRBP). |
| `widgets/time_machine_view.dart` | Vista de una etapa pasada y pie "Etapa completada". |
| `widgets/candidate_table.dart` | Tabla; para el AT, "Comparar (n)" y "Mover seleccionados a Entrevista con HM (n)"; modo `instantanea` de solo lectura. |
| `widgets/candidate_detail.dart` | Ficha con Workspace, datos, AssessFirst, entrevistas, lienzo colaborativo (etapa 5), CV y acciones por rol; modo `soloLectura`. |
| `widgets/collaborative_canvas.dart` | Lienzo de notas en tiempo real con debounce e indicador de sincronización. |
| `lib/backend/entrevistas/entrevistas_repository.dart` | Repositorio de notas (Firestore y local) y sus providers. |
| `lib/firebase_options.dart` | Generado por FlutterFire CLI: configuración web del proyecto `puerta-liverpool-2026`. Las otras plataformas lanzan `UnsupportedError`, y `main.dart` lo captura. |
| `widgets/comparison_view.dart` / `summary_view.dart` | Comparativa (tabla y radar) y Resumen (KPIs, vacantes, scatter y barras). |
| `lib/frontend/features/workspace/workspace_hub.dart` | Barra "Comunicación" (Chat, Meet, Drive; Gmail solo para AT). Chat con envío local; Meet con código estable y participantes; Drive con carpeta, "Nuevo" y compartir; Gmail con "Cargar template" (Solicitud de portafolio, Agendar llamada técnica, Seguimiento del proceso) y "Enviar". |
| `lib/frontend/features/notifications/role_alerts.dart` | `RoleAlert`, `roleAlertsProvider`, `seenRoleAlertsProvider` y `unseenRoleAlertsProvider`. |
| `lib/frontend/features/procesos/widgets/stage_stepper.dart` | Flujo de 6 círculos: `captions`, `onStepTap`, `highlightedStep`. |
| `.github/workflows/deploy.yml` | Push a `main` → `flutter build web --release --base-href "/<repo>/"` → GitHub Pages. |

## 5. Stack y dependencias

- **SDK:** Flutter 3.47.5 (canal estable) con Dart 3.13.4 en la máquina del desarrollador. La restricción del `pubspec` es `sdk: ^3.13.0`: se bajó desde `^3.13.4` cuando la máquina tenía Dart 3.13.3.
- **Plataforma principal:** web. También existe `windows/`; fuera de web, el visor de CV usa la hoja de respaldo.

| Paquete | Versión | Uso |
|---|---|---|
| `flutter_riverpod` | 3.4.3 | Estado e inyección |
| `go_router` | 18.0.1 | Navegación |
| `google_fonts` | 8.2.1 | Montserrat (UI), Roboto (Workspace), Source Serif 4 (CV de respaldo) |
| `fl_chart` | 1.2.0 | Radar, scatter y línea de presupuesto |
| `shared_preferences` | 2.5.5 | Persistencia |
| `web` | 1.1.1 | Iframe del visor de PDF |
| `url_launcher` | 6.3.2 | Módulo antiguo |
| `firebase_core` / `cloud_firestore` | 4.15.0 / 6.10.0 | Lienzo colaborativo de entrevistas (y el repositorio Firestore antiguo, sin uso) |
| `intl` | 0.20.3 | Declarado, sin uso |
| `flutter_lints` (dev) | 6.0.0 | Análisis |
| `fake_cloud_firestore` (dev) | 4.3.0 | Firestore en memoria para los tests del lienzo |

- **Assets:** `assets/fotos/`, `assets/` (JSON) y `assets/cvs/`.
- **CI/CD:** GitHub Actions → GitHub Pages. Requiere *Settings → Pages → Source: GitHub Actions*.

## 6. Estado actual

### Implementado y verificado

- Todo lo de la sección 1, con los datos reales.
- `flutter analyze` sin problemas y `flutter build web --release` compila.
- **38 tests pasan**:

| Archivo | Qué cubre |
|---|---|
| `candidatos_rules_test.dart` | Reglas, dinero y persistencia. |
| `candidatos_page_test.dart` | Flujos por rol y desplegables. |
| `etapas_flujo_test.dart` | Etapas 2 → 5 y recarga. |
| `oferta_test.dart` | Cierre, auto-descarte, alerta al HRBP y aprobación. |
| `historial_test.dart` | Bitácora, instantáneas, máquina del tiempo y resumen ejecutivo de Requisición (anchos de 1700 y 900 px; sin la pill de días en el pasado). |
| `workspace_test.dart` | Alertas por rol, correo de descarte, Chat, Gmail, barra superior y campana. |
| `lienzo_test.dart` | Repositorio de Firestore (con `fake_cloud_firestore`), dos lienzos sincronizados con debounce, modo local y lienzo solo en la etapa 5. |
| `seed_real_test.dart` | Renderiza todas las vacantes × roles × vistas con el JSON real. |
| `procesos_list_test.dart`, `hcai_scoring_test.dart`, `widget_test.dart` | Módulos antiguos. |

**Nota para tests:** en la etapa 5, la ficha tiene dos `TextField`: el del lienzo colaborativo y el de la caja de decisión del HM. Los tests que escriben la justificación usan `campoDecision` (el `TextField` dentro de `DecisionBox`, definido al final de `candidatos_page_test.dart` y `workspace_test.dart`) en lugar de `find.byType(TextField)`.

**Guion de demo del flujo completo:**

1. **HRBP** abre VAC-110 (Gerente de Tienda Departamental, $950k: la alerta de tabulador salta) y aprueba el presupuesto.
2. **HM** abre VAC-111 (Coordinador(a) de Logística E-commerce, Alineación vencida: día 3 de 2), usa "Editar Perfil / Negociar" y luego "Aprobar Alineación".
3. **Reclutador** ve la alerta "El HM aprobó la alineación", importa desde Aira (3 candidatos) y la vacante pasa a Atracción.
4. **Reclutador** marca candidatos y los mueve a entrevista con el HM: la vacante pasa a Selección.
5. **HM** abre la ficha del mejor candidato, pulsa "Seleccionar para Oferta" y confirma con justificación: el resto se descarta con correo y la vacante pasa a Oferta.
6. **HRBP** ve la alerta 💰 y pulsa "Aprobar Presupuesto": trámites de contratación iniciados.
7. Al tocar etapas pasadas en el flujo, la pantalla muestra cómo estaba cada una.
8. **Lienzo colaborativo** (requiere Firebase configurado): con dos navegadores, uno como Reclutador y otro como HM, en la misma ficha de VAC-101, lo que uno escribe aparece en el otro en tiempo real.

VAC-101 "Gerente de Proyectos E-commerce" (HM Aileen Vargas) sirve para mostrar el SLA: Héctor Galván 6 días (rojo), Patricia Ruiz 4 (ámbar) y Ana López 2 (verde).

### Pendiente o incompleto

- **CVs en PDF:** `assets/cvs/` está vacía, así que el visor muestra la hoja de respaldo. Los PDF deben nombrarse con el último segmento de `cv_path` (por ejemplo, `ana_lopez.pdf`).
- **Ficha del candidato:** muestra todas sus secciones a la vez; la propuesta es hacerlas plegables.
- **Workspace simulado:** no hay integración con Google; los mensajes y archivos nuevos viven solo mientras la hoja está abierta. No hay logotipos de Google.
- **Después de aprobar la oferta:** no hay acción para confirmar la aceptación del candidato ni para cerrar la vacante.
- **Firebase por verificar en la consola:** `flutterfire configure` ya se ejecutó. Falta confirmar que la base de datos de Firestore exista y que las reglas permitan `entrevistas/{doc}` (ver "Configuración de Firebase").
- **Casillas:** comparten el límite de 4 de la comparativa, así que para mover más de 4 candidatos hay que hacerlo en tandas.
- **Máquina del tiempo, límites de la reconstrucción:**
  - Las vacantes que ya venían avanzadas en el JSON no tienen bitácora ni valores previos; sus etapas pasadas muestran los datos actuales.
  - No se reconstruyen días ni SLA de etapas pasadas.
  - En la etapa 4 se asume que nadie había sido enviado al HM.
- **Reiniciar la demo:** requiere borrar los datos del sitio (clave `lh26`); no hay botón para hacerlo.
- **Otros:** sin modo oscuro; el encabezado de la comparativa no queda fijo al hacer scroll; los módulos antiguos siguen en el código, sin acceso desde la UI.

### Configuración de Firebase

**Estado actual:** se ejecutó `flutterfire configure --platforms=web`:
- `lib/firebase_options.dart` real (proyecto `puerta-liverpool-2026`, solo web) y `firebase.json` en la raíz;
- **pendiente de confirmar** en la consola de Firebase: que exista la base de datos de Cloud Firestore y que estén publicadas las reglas del paso 4. Si faltan, el lienzo mostrará "🔴 Sin conexión con Firestore" o "🔴 No se pudo guardar".

Estado previo, antes de la configuración (se conserva como referencia):
- `lib/firebase_options.dart` sigue siendo el provisional y no existen `firebase.json` ni `.firebaserc`;
- en la máquina del desarrollador (Windows 11, PowerShell) hay Node.js, pero **no** están instalados Firebase CLI (`firebase`) ni FlutterFire CLI (`flutterfire`), y `%LOCALAPPDATA%\Pub\Cache\bin` no está en el PATH;
- por eso el lienzo corre en "⚪ Modo local" y no sincroniza entre equipos.

Pasos para activarlo (una sola vez), en PowerShell:

0. **Respaldo:** hacer commit y push antes de configurar (todo lo posterior a `69dcdf1` está sin commit).
1. **Firebase CLI e inicio de sesión:**
   ```powershell
   npm.cmd install -g firebase-tools
   firebase.cmd login
   ```
   Se usan `npm.cmd` y `firebase.cmd` porque las versiones `.ps1` pueden bloquearse ("la ejecución de scripts está deshabilitada"). La alternativa es `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. Para verificar: `firebase.cmd projects:list`.
2. **FlutterFire CLI y PATH:**
   ```powershell
   dart pub global activate flutterfire_cli
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:LOCALAPPDATA\Pub\Cache\bin", "User")
   ```
   Después, cerrar y reabrir la terminal (y VS Code). Para verificar: `flutterfire --version`.
3. **Conectar el proyecto**, desde la raíz del repo:
   ```powershell
   flutterfire configure --platforms=web
   ```
   Elegir un proyecto existente o crear uno (ID único; por ejemplo, `puerta-liverpool-2026`). Aceptar sobrescribir `lib/firebase_options.dart`. Se generan `lib/firebase_options.dart` real y `firebase.json`.
4. **Crear Firestore** en https://console.firebase.google.com:
   - Ruta: Compilación → Firestore Database → Crear base de datos.
   - Ubicación: `nam5 (United States)`. No se puede cambiar después.
   - Modo: modo de prueba.
   - En **Reglas**, publicar:
     ```
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /entrevistas/{doc} {
           allow read, write: if request.time < timestamp.date(2026, 10, 31);
         }
       }
     }
     ```
   Estas reglas son solo para la demo: abren únicamente la colección `entrevistas` y expiran el 31 de octubre de 2026.
5. **Probar:**
   - Relanzar con `flutter run -d chrome` (no basta con **R**).
   - Abrir VAC-101 (en Selección), desplegar la ficha de un candidato y confirmar el indicador "🟢 Sincronizado en tiempo real".
   - Para ver la colaboración, abrir la misma URL en otro navegador con el otro rol y la misma ficha: lo que se escribe aparece en el otro unos 500 ms después.
   - En la consola de Firebase aparece el documento `entrevistas/candidato_{id}`.

| Síntoma | Causa probable | Solución |
|---|---|---|
| "⚪ Modo local (Firebase no configurado)" | `firebase_options.dart` provisional o la app no se relanzó | Repetir el paso 3 y relanzar con `flutter run`. |
| "🔴 Sin conexión con Firestore" o "🔴 No se pudo guardar" | Reglas sin publicar o base de datos sin crear | Revisar el paso 4 (en la consola del navegador aparece `permission-denied`). |
| `flutterfire` no se reconoce | El PATH no se actualizó | Reabrir la terminal o usar `& "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire.bat" configure --platforms=web`. |
| "running scripts is disabled" | Política de ejecución de PowerShell | Usar `npm.cmd` y `firebase.cmd`, o cambiar la política con `RemoteSigned`. |

**GitHub Pages:** el `firebase_options.dart` generado contiene la configuración web pública del proyecto, no secretos: la seguridad la dan las reglas de Firestore. Puede subirse al repo, y con eso la versión publicada también sincroniza.

### Estado del repositorio

- El último commit subido es `69dcdf1`. **Todo lo descrito en la sección 7 a partir del punto 3 está sin commit**, incluido este documento.
- Los commits van solo a nombre de Yordi-JA, **sin coautores** (preferencia del usuario).

### Cómo ejecutar

```
flutter pub get
flutter run -d chrome
```

- Tras cambios en `pubspec.yaml`, assets o el router, hay que reiniciar por completo (`R` o relanzar).
- **Sesiones anteriores al cambio de nombre:** un `flutter run` iniciado antes de que el paquete se llamara `puerta_liverpool` falla con "Couldn't resolve the package 'pulso'". Hay que detener ese proceso y relanzar; si persiste, ejecutar `flutter clean` y `flutter pub get`.
- **Firebase del lienzo:** ver la sección "Configuración de Firebase".
- **Brave:** `$env:CHROME_EXECUTABLE = "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"` y después `flutter run -d chrome`. Otra opción: `flutter run -d web-server --web-port 8080` y abrir `http://localhost:8080`.

## 7. Registro de lo realizado (cronológico) y decisiones del usuario

1. **Puesta en marcha.** Se documentó cómo correr la app en Flutter Web y en Brave. Se detectó el conflicto del SDK (`^3.13.4` contra Dart 3.13.3).
2. **Separación backend/frontend.** `lib/` se dividió en `backend/` (datos) y `frontend/` (UI). Se hicieron commits `f2eea92` (estado inicial) y `55806c6`.
3. **Corrección de la lista de Procesos.** Se arregló un assert del sliver: el `OverlayPortal` hacía `show()` durante el build y la lista usaba `findItemIndexCallback`. Commit `69dcdf1`. **Último push.**
4. **Módulo de Candidatos según `contexto2.md`,** con la paleta actual de la app. El usuario eligió **Inter** en ese momento (luego cambió a Montserrat, punto 13). Se agregaron `fl_chart`, `shared_preferences` y `web`. El JSON real vino del usuario.
5. **Sin menú lateral.** La app vive en `/candidatos`. Los colores del flujo son morado `#702F8A` (completadas) y rosa `#E10098` (actual), como en contexto2.
6. **Menos carga visual.** Vacantes en un desplegable, "Ver detalles" plegable y avisos agrupados.
7. **Etapas 1 y 2 con acciones de negocio.** Se agregaron VAC-110 y VAC-111 al JSON, con aprobación del usuario.
8. **Etapas 2 a 4.** Formulario de negociación del HM, importación desde Aira (6 candidatos nuevos con `importado: false`) y "Mover seleccionados a Entrevista con HM". Todo persiste.
9. **Hub de Workspace y alertas por rol.** Chat, Meet, Drive y Gmail con templates (UI estilo Google, Roboto, sin logotipos); SnackBar de correo al descartar; campana RBAC (`roleAlertsProvider`); tabulador de demo.
10. **Flujo de cierre.** "Seleccionar para Oferta" con justificación, auto-descarte con correos, alerta 💰 al HRBP y "Aprobar Presupuesto".
11. **Finalista sin siguiente paso claro.** "Marcar finalista" no llevaba a Oferta; se agregó el recuadro "Siguiente paso: oferta final" y el aviso para el HM.
12. **Histórico.**
    - Primero se hizo un panel informativo bajo el flujo (`StageHistoryPanel`). **El usuario lo rechazó.**
    - Se rehízo como **máquina del tiempo**: toda la pantalla en el estado de la etapa pasada, en solo lectura, con escrituras bloqueadas y bitácora de eventos.
    - El usuario pidió **quitar el banner "Estás viendo una instantánea histórica…" y el botón "Volver al presente"**. Se regresa tocando la etapa actual.
13. **Marca "Puerta Liverpool" y Montserrat.** Se renombró el paquete (`pulso` → `puerta_liverpool`) y se actualizaron los títulos web y de Windows. Se agregó la marca en la barra superior. Montserrat es global y Workspace se queda en Roboto.
14. **Barra superior reorganizada.**
    - Se eliminó el buscador.
    - El rol pasó a un menú desplegable **con solo el texto** (el usuario pidió quitar el ícono y la flecha).
    - A la derecha quedaron rol, campana (ícono centrado) y perfil.
    - Se eliminó el toast "Ahora ves la plataforma como…" al cambiar de rol.

15. **Lienzo colaborativo con Firebase.** Firestore se usa solo para las notas de entrevista en tiempo real (debounce de 500 ms, indicador de sincronización y modo local sin credenciales). `LiverhackStore` y `shared_preferences` no cambiaron. Se agregó `fake_cloud_firestore` solo para los tests.

16. **Ajuste de tests y guía de Firebase.** El lienzo agregó un `TextField` a la ficha y 2 tests que escribían en "el primer campo" empezaron a fallar; se cambiaron para usar el campo de la caja de decisión (`campoDecision`). Resultado: 36 tests pasando y el build web compilando. Se documentó paso a paso cómo conectar Firebase; la configuración real queda pendiente del usuario.

17. **Firebase configurado por el usuario.** `flutterfire configure` generó `lib/firebase_options.dart` (web, `puerta-liverpool-2026`) y `firebase.json`. Además, se aplicó un formateo automático a varios archivos del proyecto.
18. **Resumen ejecutivo de Requisición y limpieza del encabezado.** La tarjeta de Requisición (presente y máquina del tiempo) dejó de ser un grid de 4 cajas:
    - **Sin título ni descripción:** el flujo ya indica que es la Requisición (petición del usuario).
    - **Bloque A:** tres cifras de 40 px separadas por divisores verticales: "Presupuesto máximo anual", "SLA total estimado" y "Complejidad". La complejidad va en texto morado, **no como cápsula o pill**; el usuario pidió evitar ese estilo por verse "muy de IA".
    - **Bloque B:** directorio (Área con `Icons.business`, Hiring manager y Reclutamiento con `Icons.person_outline`) como texto, sin cajas; a la derecha desde 1040 px, debajo en pantallas más angostas.
    - Se quitó el multiplicador de SLA y el pie "Etapa completada" no cambia.
    - En la máquina del tiempo, el encabezado ya no muestra la pill "día X de Y".
    - Resultado: 38 tests y build web.

**Preferencias del usuario que deben respetarse:**

- Commits sin coautoría de IA.
- Mensajes y UI en español.
- Nada de banners ni botones extra en la máquina del tiempo.
- Menú de rol solo con texto.
- Sin aviso al cambiar de rol.
- Colores del flujo: `#702F8A` y `#E10098`.
- Tipografía Montserrat (Roboto solo en Workspace).
- No migrar `LiverhackStore` a Firebase: Firestore solo para el lienzo colaborativo.
- Requisición como resumen ejecutivo: sin título ni descripción, sin tarjetas o cajas por dato y sin cápsulas rellenas ("pills") para datos como la complejidad.
- En la máquina del tiempo no se muestran contadores del presente (pill de días).
