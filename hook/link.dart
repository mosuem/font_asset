import 'dart:io';

import 'package:data_assets/data_assets.dart';
import 'package:font_asset/font_asset.dart';
import 'package:font_asset/icon_treeshaker.dart' show IconTreeShaker;
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    final fonts = input.assets.fonts.toList();
    if (fonts.isEmpty) {
      return;
    }
    for (final font in fonts) {
      output.dependencies.add(font.file);
    }
    // ignore: experimental_member_use
    final recordings = input.recordedUses;
    if (recordings == null) {
      output.assets.fonts.addAll(fonts);
      return;
    }
    final fontSubsetAsset = input.assets.data
        .where((file) => file.name == 'font-subset')
        .firstOrNull;
    if (fontSubsetAsset == null) {
      output.assets.fonts.addAll(fonts);
      return;
    }
    output.dependencies.add(fontSubsetAsset.file);

    final iconTreeShaker = IconTreeShaker(
      recordings: recordings,
      fontSubset: File.fromUri(fontSubsetAsset.file),
      fonts: fonts,
      isWeb: !input.config.buildAssetTypes.contains('code_assets/code'),
    );
    for (var i = 0; i < fonts.length; i++) {
      final font = fonts[i];
      final outputFileName = '${i}_${path.basename(font.file.toFilePath())}';
      final outputPath = input.outputDirectoryShared
          .resolve(outputFileName)
          .toFilePath();
      final shookFont = await iconTreeShaker.subsetFont(
        font: font,
        outputPath: outputPath,
      );
      output.assets.fonts.add(shookFont ?? font);
    }
  });
}
