# Update feed layout

Set `AppUpdateConfig.feedBaseUrl` to the HTTPS base directory for the app's public release feed.

The feed must expose:

```text
<feed-root>/versions.txt
<feed-root>/1.1.0/release.md
<feed-root>/1.1.0/whats_new.md
<feed-root>/1.1.0/downloads.md
```

`versions.txt` contains one version directory per line. Both `1.1.0` and `v1.1.0` directory names are supported. The highest semantic version above the installed app version is used.

`downloads.md` accepts either headings followed by a URL:

```markdown
### linux_amd64_deb
https://downloads.example/app_1.1.0_amd64.deb
```

or a key and URL on one line:

```text
linux_amd64_deb: https://downloads.example/app_1.1.0_amd64.deb
```

Supported keys:

- `windows_x64_exe`, `windows_x64_zip`, `windows_x64_msi`, `windows_arm64`
- `linux_snap_store`, `linux_snap_binary`, `linux_amd64_deb`, `linux_x64_tar_gz`, `linux_x86_64_tar_gz`, `linux_x86_64_rpm`, `linux_x64`, `linux_arm64`, `linux_appimage`
- `macos_arm64_dmg`, `macos_x64_zip`, `macos_x64_dmg`, `macos_universal`
- `android_apk`, `android_play_store`
- `ios_ipa`, `ios_app_store`

Store URLs are opened externally. Installer and archive URLs are downloaded to the device's Downloads folder, then handed to the operating system. A download is not considered ready to update until the OS file-open request succeeds.

The app's update feed URL was not present in the supplied request, so the default remains the literal placeholder. No update requests are made until a real feed URL is configured.


## Web builds

After `flutter pub get`, run `flutter pub run pdf_manipulator:setup` to fetch the PDF engine's WebAssembly assets before building for web.
