# pzplayer

aplicacion musica

# 🎵 Music Player Flutter

Un reproductor de música moderno construido con **Flutter**, usando `just_audio` y `audio_service`.  
Incluye carátulas sincronizadas en tiempo real, notificaciones persistentes con controles, y un asistente IA que da consejos motivacionales en voz alta.

---

## ✨ Características

- Reproducción de audio con `just_audio`
- Notificaciones en segundo plano con portada embebida
- Sincronización en tiempo real entre UI y notificación
- Cambio de tema (oscuro/claro) con persistencia de preferencias
- Overlays flotantes y accesibilidad mejorada
- Asistente IA que sugiere canciones y da consejos motivacionales aleatorios

---

## 🏗️ Arquitectura

- **AudioProvider** centraliza la lógica de reproducción
- **AudioServiceHandler** gestiona notificaciones y estado
- **PlayerScreen** con integración del asistente IA
- **SearchResultsWidget** con navegación específica y filtrada
- **ThemeManager** para persistencia de preferencias

---

# 🎵 PZ Player 2026

Reproductor de música avanzado desarrollado con Flutter, con ecualizador profesional e integración de IA.

## 🚀 Instalación

```bash
# Clonar el repositorio
git clone [https://github.com/andreslondono11/pzplayer2026.git](https://github.com/andreslondono11/pzplayer2026.git)

# Entrar al directorio
cd pzplayer2026

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run


## 📸 Capturas de Pantalla

---

### 1. La forma estándar (Markdown)
Es la más rápida. Solo pega esto en una línea vacía:
`![Texto Alternativo](URL_DE_LA_IMAGEN)`

**Ejemplo real para tu PZ Player:**
```markdown
![Pantalla Principal](https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/1.png)
```

### 2. La forma profesional (HTML)
Esta es la que yo te recomendé porque permite **centrar** y **cambiar el tamaño** (si no, la imagen sale gigante).
```html
<p align="center">
  <img src="[https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/1.png](https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/1.png)" width="300">
</p>
```

### 3. Usando rutas relativas (La más limpia)
Si la imagen está en el mismo proyecto, no necesitas la URL larga de internet. GitHub es inteligente y la busca solo:
```markdown
![Principal](assets/screenshots/1.png)
