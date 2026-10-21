// Adds the Android and iOS project folders and the permissions the app needs.
//
// Run once from the project folder:
//
//   dart run tool/setup_platforms.dart
//
// It runs `flutter create` (which only adds missing files and never touches
// lib/), then patches AndroidManifest.xml, the Android minSdk and the iOS
// Info.plist. Running it again is safe.
import 'dart:io';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this from the project folder (where pubspec.yaml is).');
    exit(1);
  }

  stdout.writeln('1/4  flutter create (adds android/ and ios/ if missing)');
  final create = await Process.run(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
    ['create', '--org', 'com.samfred', '--project-name', 'esp32_wristband_app', '--platforms', 'android,ios', '.'],
    runInShell: true,
  );
  stdout.write(create.stdout);
  stderr.write(create.stderr);
  if (create.exitCode != 0) exit(create.exitCode);

  // flutter create adds a default widget test that does not fit this app.
  final defaultTest = File('test/widget_test.dart');
  if (defaultTest.existsSync() && defaultTest.readAsStringSync().contains('Counter increments')) {
    defaultTest.deleteSync();
  }

  stdout.writeln('2/4  Android permissions');
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var xml = manifest.readAsStringSync();
    const perms = '''
    <!-- Bluetooth Low Energy link to the band -->
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
    <!-- Talking from the phone and reaching the AI service -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
''';
    if (!xml.contains('BLUETOOTH_CONNECT')) {
      final m = RegExp(r'<manifest[^>]*>').firstMatch(xml)!;
      xml = xml.replaceRange(m.end, m.end, '\n$perms');
      xml = xml.replaceAll('android:label="esp32_wristband_app"', 'android:label="AI Band"');
      manifest.writeAsStringSync(xml);
      stdout.writeln('     permissions added');
    } else {
      stdout.writeln('     already done');
    }
  }

  stdout.writeln('3/4  Android minSdk 24');
  for (final name in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final f = File(name);
    if (!f.existsSync()) continue;
    final src = f.readAsStringSync();
    final out = src
        .replaceAll('minSdk = flutter.minSdkVersion', 'minSdk = 24')
        .replaceAll('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 24');
    if (out != src) f.writeAsStringSync(out);
  }

  stdout.writeln('4/4  iOS permission texts');
  final plist = File('ios/Runner/Info.plist');
  if (plist.existsSync()) {
    var p = plist.readAsStringSync();
    if (!p.contains('NSBluetoothAlwaysUsageDescription')) {
      const keys = '''
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>The app uses Bluetooth to connect to your AI wristband and stream voice to and from it.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>The microphone lets you talk to your assistant from the phone when the band is away.</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>bluetooth-central</string>
	</array>
''';
      final i = p.lastIndexOf('</dict>');
      p = p.replaceRange(i, i, keys);
      p = p.replaceAll('<string>Esp32 Wristband App</string>', '<string>AI Band</string>');
      plist.writeAsStringSync(p);
      stdout.writeln('     keys added');
    } else {
      stdout.writeln('     already done');
    }
  }

  stdout.writeln('\nDone. Next: flutter pub get, then flutter run --dart-define-from-file=env.json');
}
