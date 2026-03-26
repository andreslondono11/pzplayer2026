// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/core/audio/audio_provider.dart';
// import 'package:pzplayer/core/theme/app_colors.dart';

// class EqualizerScreen extends StatefulWidget {
//   const EqualizerScreen({super.key});

//   @override
//   State<EqualizerScreen> createState() => _EqualizerScreenState();
// }

// class _EqualizerScreenState extends State<EqualizerScreen> {
//   bool _isEnabled = true;

//   // Valores iniciales (se sobreescriben en initState)
//   List<double> _bandValues = [0.5, 0.5, 0.5, 0.5, 0.5];
//   final List<int> _frequencies = [60, 230, 910, 3600, 14000];

//   // Definición de Presets dentro del estado para fácil acceso
//   final Map<String, List<double>> _presets = {
//     "Plano": [0.5, 0.5, 0.5, 0.5, 0.5],
//     "Rock": [0.75, 0.65, 0.45, 0.65, 0.85],
//     "Pop": [0.45, 0.55, 0.75, 0.55, 0.45],
//     "Jazz": [0.65, 0.55, 0.45, 0.65, 0.75],
//     "Bajos": [0.95, 0.80, 0.50, 0.40, 0.30],
//     "Voces": [0.35, 0.45, 0.85, 0.65, 0.45],
//   };

//   @override
//   void initState() {
//     super.initState();
//     // 1. Sincronizamos con el estado actual del Provider al abrir
//     final audio = context.read<AudioProvider>();
//     setState(() {
//       _bandValues = List.from(audio.currentEGBands);
//       _isEnabled = audio.isEqualizerEnabled;
//     });
//   }

//   // 2. Función corregida: Envía el valor puro (0.0 a 1.0) al Provider
//   void _updateBandGain(int bandIndex, double sliderValue) {
//     if (!_isEnabled) return;
//     // El Provider se encarga de convertir este 0.0-1.0 a MiliBelios
//     context.read<AudioProvider>().setBandGain(bandIndex, sliderValue);
//   }

//   void _applyPreset(String name) {
//     setState(() {
//       _bandValues = List.from(_presets[name]!);
//       for (int i = 0; i < _bandValues.length; i++) {
//         _updateBandGain(i, _bandValues[i]);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: isDark ? Colors.black : Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           "Ecualizador Pro",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         elevation: 0,
//         actions: [
//           // Switch para encender/apagar el EQ completo
//           Switch(
//             value: _isEnabled,
//             onChanged: (value) {
//               setState(() => _isEnabled = value);
//               context.read<AudioProvider>().toggleEqualizer(value);
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 20),
//           // Selector de Presets Horizontal
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 15),
//             child: Row(
//               children: _presets.keys.map((name) {
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8),
//                   child: ActionChip(
//                     label: Text(name),
//                     backgroundColor: isDark
//                         ? Colors.white10
//                         : Colors.black.withOpacity(0.05),
//                     onPressed: () => _applyPreset(name),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//           const SizedBox(height: 40),
//           // Sliders de Frecuencia
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(
//                 5,
//                 (index) => _buildEQSlider(index, isDark),
//               ),
//             ),
//           ),
//           const SizedBox(height: 40),
//           // Botón de Reset
//           TextButton.icon(
//             onPressed: () => _applyPreset("Plano"),
//             icon: Icon(
//               Icons.refresh,
//               color: isDark ? Colors.blueGrey : AppColors.accent,
//             ),
//             label: Text(
//               "Restablecer",
//               style: TextStyle(
//                 color: isDark ? Colors.blueGrey : AppColors.accent,
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildEQSlider(int index, bool isDark) {
//     return Column(
//       children: [
//         Expanded(
//           child: RotatedBox(
//             quarterTurns: 3,
//             child: SliderTheme(
//               data: SliderTheme.of(context).copyWith(
//                 trackHeight: 4,
//                 thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
//                 overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
//               ),
//               child: Slider(
//                 value: _bandValues[index],
//                 min: 0.0,
//                 max: 1.0,
//                 activeColor: _isEnabled ? Colors.blueGrey : Colors.grey,
//                 inactiveColor: isDark ? Colors.white10 : Colors.black12,
//                 onChanged: _isEnabled
//                     ? (newValue) {
//                         setState(() {
//                           _bandValues[index] = newValue;
//                         });
//                         _updateBandGain(index, newValue);
//                       }
//                     : null,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           "${_frequencies[index]}Hz",
//           style: TextStyle(
//             fontSize: 10,
//             color: isDark ? Colors.white54 : Colors.black54,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  bool _isEnabled = true;

  // Valores de las bandas (0.0 a 1.0)
  List<double> _bandValues = [0.5, 0.5, 0.5, 0.5, 0.5];
  final List<int> _frequencies = [60, 230, 910, 3600, 14000];

  // Definición de Presets tal cual los tenías
  final Map<String, List<double>> _presets = {
    "Plano": [0.5, 0.5, 0.5, 0.5, 0.5],
    "Rock": [0.75, 0.65, 0.45, 0.65, 0.85],
    "Pop": [0.45, 0.55, 0.75, 0.55, 0.45],
    "Jazz": [0.65, 0.55, 0.45, 0.65, 0.75],
    "Bajos": [0.95, 0.80, 0.50, 0.40, 0.30],
    "Voces": [0.35, 0.45, 0.85, 0.65, 0.45],
  };

  @override
  void initState() {
    super.initState();
    // Sincronización inicial con el AudioProvider
    final audio = context.read<AudioProvider>();
    setState(() {
      _bandValues = List.from(audio.currentEGBands);
      _isEnabled = audio.isEqualizerEnabled;
    });
  }

  // Envía el valor al Provider para que afecte el audio real
  void _updateBandGain(int bandIndex, double sliderValue) {
    if (!_isEnabled) return;
    context.read<AudioProvider>().setBandGain(bandIndex, sliderValue);
  }

  void _applyPreset(String name) {
    final presetValues = _presets[name]!;
    setState(() {
      _bandValues = List.from(presetValues);
    });
    // Actualizamos el hardware a través del Provider
    context.read<AudioProvider>().setFullPreset(presetValues);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text(
          "Ecualizador Pro",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          Switch(
            value: _isEnabled,
            onChanged: (value) {
              setState(() => _isEnabled = value);
              context.read<AudioProvider>().toggleEqualizer(value);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Selector de Presets Horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: _presets.keys.map((name) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(name),
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
                    onPressed: () => _applyPreset(name),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 40),
          // Sliders de Frecuencia
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _bandValues.length,
                (index) => _buildEQSlider(index, isDark),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Botón de Reset
          TextButton.icon(
            onPressed: () => _applyPreset("Plano"),
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.blueGrey : AppColors.accent,
            ),
            label: Text(
              "Restablecer",
              style: TextStyle(
                color: isDark ? Colors.blueGrey : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEQSlider(int index, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: _bandValues[index],
                min: 0.0,
                max: 1.0,
                activeColor: _isEnabled ? Colors.blueGrey : Colors.grey,
                inactiveColor: isDark ? Colors.white10 : Colors.black12,
                onChanged: _isEnabled
                    ? (newValue) {
                        setState(() {
                          _bandValues[index] = newValue;
                        });
                        _updateBandGain(index, newValue);
                      }
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "${_frequencies[index]}Hz",
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
