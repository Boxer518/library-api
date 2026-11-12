import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Поле, которое сообщает текст не на каждый символ, а после паузы.
class DebouncedTextField extends StatefulWidget {
  const DebouncedTextField({
    required this.value,
    required this.onDebounced,
    required this.label,
    this.keyboardType,
    this.delay = const Duration(milliseconds: 300),
    super.key,
  });

  final String value;
  final ValueChanged<String> onDebounced;
  final String label;
  final TextInputType? keyboardType;
  final Duration delay;

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  late final TextEditingController _controller;
  Timer? _timer;
  var _applyingExternal = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(DebouncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Пока таймер жив, в поле незавершённый ввод. Ответ списка приходит
    // через сотни миллисекунд и иначе стирает уже набранные символы.
    if (_timer?.isActive ?? false) {
      return;
    }
    if (widget.value != _controller.text) {
      _applyingExternal = true;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
      _applyingExternal = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    if (_applyingExternal) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(widget.delay, () {
      _timer = null;
      if (!mounted) {
        return;
      }
      widget.onDebounced(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: _onChanged,
    );
  }
}
