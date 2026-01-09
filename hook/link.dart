import 'dart:io';

import 'package:data_assets/data_assets.dart';
import 'package:font_asset/font_asset.dart';
import 'package:font_asset/icon_treeshaker.dart' show IconTreeShaker;
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    final fonts = input.assets.fonts.toList();
    print('Starting to treeshake $fonts');
    final treeshaker = Treeshaker(fonts, input.outputDirectory);
    for (final font in fonts) {
      print('Shaking $font');
      final shookFont = await treeshaker.shake(font, input.fontConfig());
      output.assets.fonts.add(shookFont);
    }
  });
}

extension on LinkInput {
  FlutterFontConfig fontConfig() {
    return FlutterFontConfig(
      appDill: fileFromAsset('appDill'),
      fontSubset: fileFromAsset('font-subset'),
      constFinder: fileFromAsset('const_finder'),
      dart: File(
        '${fileFromAsset('flutterRoot').readAsStringSync()}/bin/cache/dart-sdk/bin/dart',
      ),
      isWeb: false,
    );
  }

  File fileFromAsset(String name) =>
      File.fromUri(assets.data.firstWhere((file) => file.name == name).file);
}

class FlutterFontConfig {
  final File appDill;
  final File dart;
  final File constFinder;
  final File fontSubset;
  final bool isWeb;

  FlutterFontConfig({
    required this.appDill,
    required this.dart,
    required this.constFinder,
    required this.fontSubset,
    required this.isWeb,
  });
}

class Treeshaker {
  final List<FontAsset> fonts;

  final Uri outputDirectory;

  Treeshaker(this.fonts, this.outputDirectory);

  Future<FontAsset> shake(FontAsset font, FlutterFontConfig flutter) async {
    final subsetFont =
        await IconTreeShaker(
          appDill: flutter.appDill,
          dart: flutter.dart,
          constFinder: flutter.constFinder,
          fontSubset: flutter.fontSubset,
          fonts: fonts,
          isWeb: flutter.isWeb,
        ).subsetFont(
          font: font,
          outputPath: outputDirectory
              .resolve(path.basename(font.file.path))
              .path,
        );

    return subsetFont ?? font;
  }
}
