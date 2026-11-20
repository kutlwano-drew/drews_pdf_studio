import 'package:flutter/widgets.dart';

enum AppKeyboardAction { undo, redo, open, save }

class AppKeyboardIntent extends Intent {
  const AppKeyboardIntent(this.action);
  final AppKeyboardAction action;
}
