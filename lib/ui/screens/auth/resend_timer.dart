import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme.dart';

class ResendController extends ChangeNotifier {
  Timer? _timer;
  int _remaining = 0;

  int get remaining => _remaining;
  bool get canResend => _remaining == 0;

  void start(int seconds) {
    _timer?.cancel();
    _remaining = seconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _remaining = (_remaining - 1).clamp(0, seconds);
      if (_remaining == 0) t.cancel();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class ResendButton extends StatelessWidget {
  final ResendController controller;
  final bool loading;
  final VoidCallback onResend;

  const ResendButton({
    super.key,
    required this.controller,
    required this.loading,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.canResend) {
          final m = (controller.remaining ~/ 60).toString().padLeft(2, '0');
          final s = (controller.remaining % 60).toString().padLeft(2, '0');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'ارسال مجدد کد تا $m:$s دیگر',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return TextButton(
          onPressed: loading ? null : onResend,
          child: const Text('ارسال مجدد کد'),
        );
      },
    );
  }
}

class OtpField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final VoidCallback? onCompleted;

  const OtpField({
    super.key,
    required this.controller,
    required this.validator,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLength: 6,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [_DigitsFormatter()],
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 12),
        validator: validator,
        onChanged: (v) {
          if (v.length == 6) onCompleted?.call();
        },
        decoration: const InputDecoration(counterText: '', hintText: '------'),
      );
}

class _DigitsFormatter extends TextInputFormatter {
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final unit in input.runes) {
      if (unit >= 0x06F0 && unit <= 0x06F9) {
        buffer.writeCharCode(unit - 0x06F0 + 0x30);
      } else if (unit >= 0x0660 && unit <= 0x0669) {
        buffer.writeCharCode(unit - 0x0660 + 0x30);
      } else if (unit >= 0x30 && unit <= 0x39) {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = normalize(newValue.text);
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
