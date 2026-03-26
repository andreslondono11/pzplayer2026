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


🛠️ Stack Tecnológico

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
