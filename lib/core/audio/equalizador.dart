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

//   // Valores de las bandas (0.0 a 1.0)
//   List<double> _bandValues = [0.5, 0.5, 0.5, 0.5, 0.5];
//   final List<int> _frequencies = [60, 230, 910, 3600, 14000];

//   // Definición de Presets tal cual los tenías
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
//     // Sincronización inicial con el AudioProvider
//     final audio = context.read<AudioProvider>();
//     setState(() {
//       _bandValues = List.from(audio.currentEGBands);
//       _isEnabled = audio.isEqualizerEnabled;
//     });
//   }

//   // Envía el valor al Provider para que afecte el audio real
//   void _updateBandGain(int bandIndex, double sliderValue) {
//     if (!_isEnabled) return;
//     context.read<AudioProvider>().setBandGain(bandIndex, sliderValue);
//   }

//   void _applyPreset(String name) {
//     final presetValues = _presets[name]!;
//     setState(() {
//       _bandValues = List.from(presetValues);
//     });
//     // Actualizamos el hardware a través del Provider
//     context.read<AudioProvider>().setFullPreset(presetValues);
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
//                 _bandValues.length,
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
  // Definición de Presets
  final Map<String, List<double>> _presets = {
    "Plano": [0.5, 0.5, 0.5, 0.5, 0.5],
    "Rock": [0.75, 0.65, 0.45, 0.65, 0.85],
    "Pop": [0.45, 0.55, 0.75, 0.55, 0.45],
    "Jazz": [0.65, 0.55, 0.45, 0.65, 0.75],
    "Bajos": [0.95, 0.80, 0.50, 0.40, 0.30],
    "Voces": [0.35, 0.45, 0.85, 0.65, 0.45],
  };

  final List<int> _frequencies = [60, 230, 910, 3600, 14000];
  late String _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = "Plano";

    // Log inicial
    print("🎚️ [EQ] Pantalla de ecualizador iniciada");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = context.read<AudioProvider>();
      print("🎚️ [EQ] Valores iniciales del Provider: ${audio.currentEGBands}");
    });
  }

  void _applyPreset(String name) {
    print("🎚️ [EQ UI] Botón presionado: $name");

    setState(() {
      _selectedPreset = name;
    });

    final presetValues = _presets[name]!;
    print("🎚️ [EQ UI] Valores a aplicar: $presetValues");

    // Actualizar el Provider
    context.read<AudioProvider>().setFullPreset(presetValues);
  }

  void _updateBand(int index, double value) {
    print("🎚️ [EQ UI] Slider movido - Banda $index: Valor $value");

    // Deseleccionar el preset visualmente si se mueve manualmente
    if (_selectedPreset != "Personalizado") {
      setState(() {
        _selectedPreset = "Personalizado";
      });
    }

    // Actualizar el Provider
    context.read<AudioProvider>().setBandGain(index, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        // Sincronizamos el estado local con el del Provider
        List<double> currentBands = audio.currentEGBands;
        bool isEnabled = audio.isEqualizerEnabled;

        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              "Ecualizador",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    print("🎚️ [EQ UI] Switch Ecualizador: $value");
                    context.read<AudioProvider>().toggleEqualizer(value);
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ],
          ),
          body: OrientationBuilder(
            builder: (context, orientation) {
              // 👇 DETECTAMOS SI ES LANDSCAPE
              final bool isLandscape = orientation == Orientation.landscape;

              if (isLandscape) {
                // --- LAYOUT LANDSCAPE ---
                return Row(
                  children: [
                    // Columna Izquierda: Controles (Presets y Reset)
                    Expanded(
                      flex: 2, // Ocupa menos espacio que los sliders
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Título Presets
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Presets",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // Lista Vertical Compacta de Presets
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              itemCount: _presets.length,
                              itemBuilder: (context, index) {
                                final name = _presets.keys.elementAt(index);
                                final isSelected = _selectedPreset == name;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: FilterChip(
                                    label: Center(child: Text(name)),
                                    selected: isSelected,
                                    onSelected: (_) => _applyPreset(name),
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.2),
                                    checkmarkColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black54),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor: isDark
                                        ? Colors.white10
                                        : Colors.black.withOpacity(0.05),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Botón Reset
                          TextButton.icon(
                            onPressed: () => _applyPreset("Plano"),
                            icon: Icon(
                              Icons.refresh,
                              color: isDark
                                  ? Colors.blueGrey
                                  : AppColors.accent,
                            ),
                            label: Text(
                              "Restablecer",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.blueGrey
                                    : AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Separador Vertical
                    VerticalDivider(
                      color: isDark ? Colors.white12 : Colors.black12,
                      thickness: 1,
                    ),

                    // Columna Derecha: Sliders
                    Expanded(
                      flex: 5, // Ocupa más espacio para los sliders
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(currentBands.length, (index) {
                            return Expanded(
                              child: _buildVerticalSlider(
                                index: index,
                                value: currentBands[index],
                                isEnabled: isEnabled,
                                isDark: isDark,
                                frequency: _frequencies[index],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // --- LAYOUT RETRATO (ORIGINAL) ---
                return Column(
                  children: [
                    const SizedBox(height: 10),

                    // --- CHIPS DE PRESETS ---
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: _presets.length,
                        itemBuilder: (context, index) {
                          final name = _presets.keys.elementAt(index);
                          final isSelected = _selectedPreset == name;

                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(name),
                              selected: isSelected,
                              onSelected: (_) => _applyPreset(name),
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- VISUALIZADOR DE BARRAS (SLIDERS VERTICALES) ---
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(currentBands.length, (index) {
                          return _buildVerticalSlider(
                            index: index,
                            value: currentBands[index],
                            isEnabled: isEnabled,
                            isDark: isDark,
                            frequency: _frequencies[index],
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- BOTÓN RESET ---
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
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildVerticalSlider({
    required int index,
    required double value,
    required bool isEnabled,
    required bool isDark,
    required int frequency,
  }) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          SizedBox(
            height: 250,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14.0,
                  ),
                  activeTrackColor: isEnabled ? AppColors.primary : Colors.grey,
                  inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                  thumbColor: isEnabled ? AppColors.primary : Colors.grey,
                  overlayColor: isEnabled
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: isEnabled
                      ? (newValue) {
                          _updateBand(index, newValue);
                        }
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            frequency >= 1000 ? "${frequency / 1000}k" : "$frequency",
            style: TextStyle(
              fontSize: 11,
              color: isEnabled
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
