import 'package:material_ui/material_ui.dart';

/// После закрытия формы поверх карточки карточка перечитывает запись.
class ReloadWhenShown extends StatefulWidget {
  const ReloadWhenShown({required this.onShow, required this.child, super.key});

  final VoidCallback onShow;
  final Widget child;

  @override
  State<ReloadWhenShown> createState() => _ReloadWhenShownState();
}

class _ReloadWhenShownState extends State<ReloadWhenShown> {
  var _current = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (current && !_current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onShow();
        }
      });
    }
    _current = current;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
