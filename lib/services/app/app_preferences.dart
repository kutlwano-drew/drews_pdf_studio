import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _onboardingKey = 'pdf_studio.onboarding_complete';

  Future<bool> isFirstLaunch() async {
    final preferences = await SharedPreferences.getInstance();
    return !(preferences.getBool(_onboardingKey) ?? false);
  }

  Future<void> completeFirstLaunch() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingKey, true);
  }
}
