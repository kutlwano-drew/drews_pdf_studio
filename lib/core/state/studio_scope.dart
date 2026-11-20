import 'package:flutter/widgets.dart';
import 'studio_controller.dart';

class StudioScope extends InheritedNotifier<StudioController> {
  const StudioScope({super.key, required StudioController controller, required super.child})
      : super(notifier: controller);

  static StudioController watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StudioScope>()!.notifier!;

  static StudioController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StudioScope>()!.notifier!;
}
