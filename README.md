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

## 🚀 Instalación

```bash
git clone https://github.com/tuusuario/music_player_flutter.git
cd music_player_flutter
flutter pub get
flutter run


## 📸 Capturas de Pantalla

<h2>📸 Capturas de Pantalla</h2>

<img src="assets/screenshots/1.png" alt="Pantalla Principal" width="300"/>
<img src="assets/screenshots/2.png" alt="Notificación" width="300"/>
<img src="assets/screenshots/3.png" alt="Asistente IA" width="300"/>

