import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_keyboard_intent.dart';

class AppKeyboardShortcuts extends StatelessWidget {
  const AppKeyboardShortcuts({
    super.key,
    required this.child,
    required this.onUndo,
    required this.onRedo,
    required this.onOpen,
    required this.onSave,
  });

  final Widget child;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyZ, control: true): AppKeyboardIntent(AppKeyboardAction.undo),
          SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): AppKeyboardIntent(AppKeyboardAction.redo),
          SingleActivator(LogicalKeyboardKey.keyY, control: true): AppKeyboardIntent(AppKeyboardAction.redo),
          SingleActivator(LogicalKeyboardKey.keyO, control: true): AppKeyboardIntent(AppKeyboardAction.open),
          SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): AppKeyboardIntent(AppKeyboardAction.save),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            AppKeyboardIntent: CallbackAction<AppKeyboardIntent>(onInvoke: (intent) {
              switch (intent.action) {
                case AppKeyboardAction.undo: onUndo(); break;
                case AppKeyboardAction.redo: onRedo(); break;
                case AppKeyboardAction.open: onOpen(); break;
                case AppKeyboardAction.save: onSave(); break;
              }
              return null;
            }),
          },
          child: Focus(autofocus: true, child: child),
        ),
      );
}
