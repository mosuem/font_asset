import 'dart:io';

import 'package:font_asset/build_helpers.dart' show flutterRoot;
import 'package:font_asset/font_asset.dart';
import 'package:font_asset/icon_treeshaker.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    final fonts = input.assets.fonts.toList();
    print('Starting to treeshake $fonts');
    final treeshaker = Treeshaker(fonts, input.outputDirectory);
    for (final font in fonts) {
      print('Shaking $font');
      final shookFont = await treeshaker.shake(font, input.config.flutter);
      output.assets.fonts.add(shookFont);
    }
  });
}

extension on LinkConfig {
  FlutterConfig get flutter {
    return FlutterConfig(
      appDill:
          Directory(
                '/home/mosum/projects/font_asset_test/.dart_tool/flutter_build/',
              )
              .listSync(recursive: true)
              .whereType<File>()
              .firstWhere((file) => file.path.endsWith('app.dill')),
      dart: File('${flutterRoot}bin/cache/dart-sdk/bin/dart'),
      constFinder: File(
        '${flutterRoot}bin/cache/artifacts/engine/linux-x64/const_finder.dart.snapshot',
      ),
      fontSubset: File(
        '${flutterRoot}bin/cache/artifacts/engine/linux-x64/font-subset',
      ),
      isWeb: false,
    );
  }
}

class FlutterConfig {
  final File appDill;
  final File dart;
  final File constFinder;
  final File fontSubset;
  final bool isWeb;

  FlutterConfig({
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

  Future<FontAsset> shake(FontAsset font, FlutterConfig flutter) async {
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
