import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/utils/formatters.dart';
import '../theme.dart';

typedef _Curve = double Function(double hz);

class _Preset {
  final String name;
  final _Curve curve;

  const _Preset(this.name, this.curve);
}

final _presets = <_Preset>[
  _Preset('تخت', (_) => 0),
  _Preset('تقویت بیس', (hz) => hz <= 150 ? 0.8 : (hz <= 500 ? 0.45 : 0)),
  _Preset('وکال', (hz) => hz <= 150 ? -0.3 : (hz <= 500 ? 0.15 : (hz <= 4000 ? 0.6 : 0.2))),
  _Preset('تقویت زیر', (hz) => hz >= 8000 ? 0.8 : (hz >= 2500 ? 0.45 : 0)),
  _Preset('راک', (hz) => hz <= 150 ? 0.6 : (hz <= 500 ? 0.2 : (hz <= 4000 ? -0.15 : 0.6))),
];

Future<void> showEqualizerSheet(BuildContext context, AndroidEqualizer equalizer) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => EqualizerSheet(equalizer: equalizer),
  );
}

class EqualizerSheet extends StatefulWidget {
  final AndroidEqualizer equalizer;

  const EqualizerSheet({super.key, required this.equalizer});

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  AndroidEqualizerParameters? _params;
  bool _failed = false;
  String? _preset;

  AndroidEqualizer get _eq => widget.equalizer;

  @override
  void initState() {
    super.initState();
    _eq.parameters.then((p) {
      if (mounted) setState(() => _params = p);
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  void _ensureEnabled() {
    if (!_eq.enabled) _send(_eq.setEnabled(true));
  }

  void _send(Future<void> call) => call.catchError((Object _) {});

  void _setGain(AndroidEqualizerBand band, double value) {
    if (_preset != null) setState(() => _preset = null);
    _ensureEnabled();
    _send(band.setGain(value));
  }

  void _applyPreset(_Preset preset) {
    final params = _params;
    if (params == null) return;
    setState(() => _preset = preset.name);
    _ensureEnabled();
    for (final band in params.bands) {
      final f = preset.curve(band.centerFrequency).clamp(-1.0, 1.0);
      final gain = f >= 0 ? f * params.maxDecibels : -f * params.minDecibels;
      _send(band.setGain(gain));
    }
  }

  String _freq(double hz) =>
      hz >= 1000 ? '${(hz / 1000).toStringAsFixed(hz >= 10000 ? 0 : 1)}k' : '${hz.round()}';

  String _db(double v) {
    final r = v.round();
    return r > 0 ? '+$r' : '$r';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: StreamBuilder<bool>(
          stream: _eq.enabledStream,
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.graphic_eq_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اکولایزر',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            enabled ? 'فعال' : 'غیرفعال',
                            style: textTheme.bodySmall?.copyWith(
                              color: enabled ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: enabled, onChanged: (v) => _send(_eq.setEnabled(v))),
                  ],
                ),
                const SizedBox(height: 16),
                if (_failed)
                  const _Message('اکولایزر روی این دستگاه پشتیبانی نمی‌شود')
                else if (_params == null)
                  const _Message('ابتدا یک آهنگ را پخش کنید')
                else ...[
                  _buildPresets(),
                  const SizedBox(height: 20),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: enabled ? 1 : 0.45,
                    child: _buildBands(_params!, textTheme),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => _applyPreset(_presets.first),
                      icon: const Icon(Icons.restart_alt_rounded, size: 20),
                      label: const Text('بازنشانی'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresets() => SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _presets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final preset = _presets[i];
            final selected = _preset == preset.name;
            return _PresetChip(
              label: preset.name,
              selected: selected,
              onTap: () => _applyPreset(preset),
            );
          },
        ),
      );

  Widget _buildBands(AndroidEqualizerParameters params, TextTheme textTheme) {
    final labelStyle = textTheme.labelSmall?.copyWith(color: AppColors.textSecondary);
    return SizedBox(
      height: 300,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            for (final band in params.bands)
              Expanded(
                child: StreamBuilder<double>(
                  stream: band.gainStream,
                  builder: (context, snapshot) {
                    final gain = (snapshot.data ?? band.gain)
                        .clamp(params.minDecibels, params.maxDecibels);
                    return Column(
                      children: [
                        Text(
                          toPersianDigits(_db(gain)),
                          textDirection: TextDirection.ltr,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: gain.round() == 0 ? AppColors.textSecondary : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              RotatedBox(
                                quarterTurns: -1,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 10,
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: AppColors.surfaceHigh,
                                    thumbColor: Colors.white,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 11,
                                      elevation: 3,
                                      pressedElevation: 6,
                                    ),
                                    overlayColor: AppColors.primary.withValues(alpha: 0.18),
                                    overlayShape:
                                        const RoundSliderOverlayShape(overlayRadius: 22),
                                    trackShape: const RoundedRectSliderTrackShape(),
                                  ),
                                  child: Slider(
                                    min: params.minDecibels,
                                    max: params.maxDecibels,
                                    value: gain,
                                    onChanged: (v) => _setGain(band, v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_freq(band.centerFrequency), style: labelStyle),
                        Text('Hz', style: labelStyle?.copyWith(fontSize: 9)),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
}
