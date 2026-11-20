class AppUpdateRelease {
  const AppUpdateRelease({
    required this.version,
    required this.releaseNotes,
    required this.whatsNew,
    required this.downloads,
    this.checksums = const {},
  });

  final String version;
  final String releaseNotes;
  final String whatsNew;
  final Map<String, String> downloads;
  final Map<String, String> checksums;
}
