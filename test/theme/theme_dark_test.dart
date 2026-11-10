import 'dart:io';

import 'package:clock_app/common/data/paths.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/theme/data/default_color_schemes.dart';
import 'package:clock_app/theme/logic/theme_migration.dart';
import 'package:clock_app/theme/theme.dart';
import 'package:clock_app/theme/types/color_scheme.dart';
import 'package:clock_app/theme/types/theme_brightness.dart';
import 'package:clock_app/theme/utils/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  late GetStorage storage;
  final colors = appSettings.getGroup("Appearance").getGroup("Colors");

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tmp = Directory.systemTemp.createTempSync('chrono_theme');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    await initializeAppDataDirectory();
    await GetStorage.init();
    storage = GetStorage();
  });

  setUp(() async {
    await storage.remove(themeMigrationKey);
  });

  test('Theme setting defaults to System default', () {
    expect(appSettings.getSetting("Theme").value, ThemeBrightness.system);
  });

  test('default dark scheme is One UI Dark and is treated as dark', () {
    expect(defaultDarkColorScheme.name, 'One UI Dark');
    expect(getColorScheme(defaultDarkColorScheme).brightness, Brightness.dark);
    expect(getColorScheme(defaultColorScheme).brightness, Brightness.light);
    final theme = getTheme(colorSchemeData: defaultDarkColorScheme);
    expect(theme.brightness, Brightness.dark);
    expect(theme.iconTheme.color, defaultDarkColorScheme.onBackground);
  });

  test('users who never had dark mode get One UI Dark', () async {
    colors.getSetting("System Dark Mode").setValueWithoutNotify(false);
    colors.getSetting("Dark Color Scheme").setValueWithoutNotify(
        defaultColorSchemes.firstWhere((s) => s.name == 'Dark'));
    await migrateThemeSettings(storage: storage);
    expect(
        (colors.getSetting("Dark Color Scheme").value as ColorSchemeData).name,
        'One UI Dark');
    expect(storage.read(themeMigrationKey), true);
  });

  test('a dark scheme chosen with System Dark Mode on is kept', () async {
    colors.getSetting("System Dark Mode").setValueWithoutNotify(true);
    colors.getSetting("Dark Color Scheme").setValueWithoutNotify(
        defaultColorSchemes.firstWhere((s) => s.name == 'Amoled'));
    await migrateThemeSettings(storage: storage);
    expect(
        (colors.getSetting("Dark Color Scheme").value as ColorSchemeData).name,
        'Amoled');
    colors.getSetting("System Dark Mode").setValueWithoutNotify(false);
  });

  test('Material You Light/Dark choice carries over to Theme', () async {
    colors.getSetting("Use Material You").setValueWithoutNotify(true);
    colors.getSetting("Brightness").setValueWithoutNotify(2); // dark
    await migrateThemeSettings(storage: storage);
    expect(appSettings.getSetting("Theme").value, ThemeBrightness.dark);
    colors.getSetting("Use Material You").setValueWithoutNotify(false);
    colors.getSetting("Brightness").setValueWithoutNotify(0);
    appSettings.getSetting("Theme").setValueWithoutNotify(0);
  });

  test('Material You cards stand out from the page', () {
    for (final b in Brightness.values) {
      final s = withDistinctCards(
          ColorScheme.fromSeed(seedColor: Colors.blue, brightness: b));
      // ignore: deprecated_member_use
      expect(s.surface, isNot(s.background));
    }
  });
}
