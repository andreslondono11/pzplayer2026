🎵 Music Player 2026

PZ Player 2026 no es solo un reproductor de música; es una experiencia sonora inteligente. Desarrollado con Flutter, combina un motor de audio de alto rendimiento con la potencia de la Inteligencia Artificial para ofrecerte no solo tus canciones favoritas, sino motivación y control total sobre tu sonido.

✨ Características Destacadas

🎧 Experiencia de Audio Superior

Motor Just Audio: Reproducción de alta fidelidad sin interrupciones y con soporte para múltiples formatos.

Ecualizador Pro: Ajuste de precisión con un ecualizador de 5 bandas (60Hz a 14kHz) y presets optimizados (Rock, Pop, Jazz, Bass Boost, Voces).

Notificaciones Inteligentes: Control total desde la barra de estado y pantalla de bloqueo, con sincronización de carátulas y estado de reproducción en tiempo real.

🤖 Inteligencia Artificial Motivacional

Asistente Gemini IA: Un compañero integrado que analiza tu momento y te ofrece consejos motivacionales por voz y texto.

Sugerencias Inteligentes: Pregúntale qué escuchar o simplemente deja que te inspire con frases aleatorias para potenciar tu día.

🎨 Diseño y Personalización

Interfaz Adaptativa: Diseño moderno con soporte nativo para Modo Oscuro y Modo Claro.

Persistencia de Preferencias: Tus ajustes de ecualización y temas se guardan automáticamente para tu próxima sesión.

Exploración Rápida: Escaneo inteligente de archivos locales organizado por álbumes, artistas y carpetas.

📸 Capturas de Pantalla

<p align="center">
<img src="https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/1.png" width="280" alt="Pantalla Principal">
<img src="https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/3.png" width="280" alt="Pantalla Principal">
<<img src="https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/2.png" width="280" alt="Pantalla Principal">"Asistente IA">
<img src="https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/4.png" width="280" alt="Pantalla Principal">
<img src="https://raw.githubusercontent.com/andreslondono11/pzplayer2026/main/assets/screenshots/5.png" width="280" alt="Pantalla Principal">
  
</p>
🏗️ Arquitectura del Sistema

El proyecto sigue una arquitectura limpia y reactiva:

AudioProvider: El corazón de la app. Gestiona el estado global, la lista de reproducción y la lógica del ecualizador mediante Provider.

AudioServiceHandler: Implementación robusta de audio_service para garantizar que la música nunca se detenga, incluso con la pantalla apagada.

AI Service Engine: Capa de comunicación con la API de Google Generative AI para el procesamiento de lenguaje natural.

ThemeManager: Gestor centralizado de estilos visuales con persistencia local.

🚀 Guía de Instalación

Prepara tu entorno de desarrollo y lanza PZ Player en minutos:

# 1. Clonar el repositorio
git clone [https://github.com/andreslondono11/pzplayer2026.git](https://github.com/andreslondono11/pzplayer2026.git)

# 2. Entrar a la carpeta del proyecto
cd pzplayer2026

# 3. Obtener todas las dependencias de Flutter
flutter pub get

# 4. Lanzar la aplicación (Asegúrate de tener un emulador o dispositivo conectado)
flutter run



# 🚀 PZ Player: Atmosphere Edition 2026

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

> **"La música no solo se escucha, se siente."** > PZ Player transforma la interacción con tu biblioteca local mediante una experiencia inmersiva, motivacional y de alto rendimiento técnico.

---

## 🆕 Novedades de la Versión 2026

### 🎥 Nuevo "Modo Atmósfera" (Env Mode)
Hemos llevado la estética al siguiente nivel integrando fondos de video dinámicos sin comprometer la fluidez del sistema.
* **Video de Fondo Hi-Fi:** Soporte para fondos inmersivos de alta calidad.
* **Pre-caching Engine:** Sistema de carga anticipada que garantiza que el video esté listo desde el primer segundo, eliminando pantallas negras.
* **Minimalist UI:** Una interfaz limpia que prioriza el movimiento y la armonía visual.

### 🎙️ Asistente de Motivación IA (TTS Engine)
El reproductor ahora es tu compañero de entrenamiento y concentración.
* **Palabras Inspiradoras:** Al cambiar de pista en el *Modo Atmósfera*, el motor TTS genera frases audibles para elevar tu energía.
* **Audio Mixing:** Integración fluida que sincroniza la voz con la música sin interrumpir la reproducción.

### 🛠️ Gestión Avanzada de Biblioteca
Diseñado para quienes aman tener el control total de sus archivos.
* **Búsqueda Inteligente:** Panel de resultados dinámico accesible desde la pantalla principal para encontrar pistas, álbumes o artistas al instante.
* **Technical Insights para Audiófilos:** Visualización de metadatos profundos:
    * Formato de archivo (`MP3`, `FLAC`, `WAV`, `AAC`).
    * Tamaño exacto en MB.
    * Ruta física (Path) del archivo en el dispositivo.
* **Smart Playlists:** Organización optimizada con soporte nativo para temas Claro y Oscuro.

### ⚡ Ingeniería, Optimización y Estabilidad
Bajo el capó, hemos reconstruido el núcleo para una experiencia libre de errores.
* **Zero Memory Leaks:** Reestructuración completa del ciclo de vida de los controladores (`dispose()`), eliminando fugas de memoria.
* **Consola Limpia:** Optimización de *listeners* de audio para eliminar errores de contexto y logs innecesarios.
* **Interfaz Pulida:** Eliminación de *paddings* fantasmales y optimización del espacio en paneles de pestañas (Álbumes, Artistas, Carpetas, Géneros).

---

## 🛠️ Stack Tecnológico
* **Frontend:** Flutter & Dart.
* **Audio Core:** `just_audio` / `audio_service`.
* **Video Engine:** `video_player` con optimización de mezcla de audio.
* **Persistence:** `shared_preferences`.
* **Metadata:** `on_audio_query`.

---

## 📱 Optimización de Hardware
Especialmente optimizado para dispositivos de alto rendimiento (Probado en **vivo Y38 5G**), garantizando que el renderizado de video pesado y el procesamiento de voz ocurran de forma paralela y fluida.

---
Desarrollado con ❤️ por **PZ PLATINUM**
Herramienta

Función

Flutter / Dart

Desarrollo multiplataforma UI/UX.

Just Audio

Motor de reproducción de audio y manejo de clips.

Audio Service

Soporte para reproducción en segundo plano.

Provider

Gestión de estado y comunicación entre componentes.

Google Gemini API

Motor de Inteligencia Artificial y sugerencias.

Shared Preferences

Almacenamiento local de ajustes y temas.

Hecho con ❤️ por Andrés Londoño
