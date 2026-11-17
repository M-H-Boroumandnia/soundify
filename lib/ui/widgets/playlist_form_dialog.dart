import 'package:material_ui/material_ui.dart';

import '../../core/utils/validators.dart';

class PlaylistFormResult {
  final String name;
  final String description;

  const PlaylistFormResult(this.name, this.description);
}

Future<PlaylistFormResult?> showPlaylistFormDialog(
  BuildContext context, {
  String initialName = '',
  String initialDescription = '',
}) {
  return showDialog<PlaylistFormResult>(
    context: context,
    useRootNavigator: true,
    builder: (_) =>
        _PlaylistFormDialog(initialName: initialName, initialDescription: initialDescription),
  );
}

class _PlaylistFormDialog extends StatefulWidget {
  final String initialName;
  final String initialDescription;

  const _PlaylistFormDialog({required this.initialName, required this.initialDescription});

  @override
  State<_PlaylistFormDialog> createState() => _PlaylistFormDialogState();
}

class _PlaylistFormDialogState extends State<_PlaylistFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _description = TextEditingController(text: widget.initialDescription);

  bool get _isEdit => widget.initialName.isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(PlaylistFormResult(_name.text.trim(), _description.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(_isEdit ? 'ویرایش پلی‌لیست' : 'پلی‌لیست جدید'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: width > 520 ? 480 : double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'نام پلی‌لیست'),
                validator: (v) => Validators.required(v, 'نام پلی‌لیست'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('انصراف')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _submit,
          child: Text(_isEdit ? 'ذخیره' : 'ایجاد'),
        ),
      ],
    );
  }
}
