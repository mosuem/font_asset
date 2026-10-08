import 'dart:io' show File, Platform;

import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

import '../font_asset.dart';

void addFont(
  BuildInput input,
  BuildOutputBuilder output, {
  required String family,
  required String filePath,
  String? name,
  int? weight,
  String? style,
}) {
  if (!input.config.buildAssetTypes.contains(fontAssetType)) {
    return;
  }
  final file = input.packageRoot.resolve(filePath);
  output.dependencies.add(file);
  output.assets.fonts.add(
    FontAsset(
      family: family,
      name: name ?? filePath,
      file: file,
      weight: weight,
      style: style,
      package: input.packageName,
    ),
    routing: input.config.linkingEnabled
        ? const ToLinkHook('font_asset')
        : const ToAppBundle(),
  );
}

void addFontFamily(
  BuildInput input,
  BuildOutputBuilder output, {
  required String family,
  required List<({Uri filePath, int? weight})> fonts,
}) {
  if (!input.config.buildAssetTypes.contains(fontAssetType)) {
    return;
  }
  for (final e in fonts) {
    output.dependencies.add(e.filePath);
  }
  output.assets.fonts.addAll(
    fonts.map(
      (e) => FontAsset(
        file: e.filePath,
        family: family,
        package: input.packageName,
        weight: e.weight,
      ),
    ),
    routing: input.config.linkingEnabled
        ? const ToLinkHook('font_asset')
        : const ToAppBundle(),
  );
}

void addMaterialFont(BuildInput input, BuildOutputBuilder output) {
  if (!input.config.buildAssetTypes.contains(fontAssetType)) {
    return;
  }
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final file = Uri.file(
    path.join(
      flutterRoot,
      'bin',
      'cache',
      'artifacts',
      'material_fonts',
      'MaterialIcons-Regular.otf',
    ),
  );
  output.dependencies.add(file);
  output.assets.fonts.add(
    FontAsset(
      family: 'MaterialIcons',
      name: 'fonts/MaterialIcons-Regular.otf',
      file: file,
      package: input.packageName,
    ),
    routing: input.config.linkingEnabled
        ? const ToLinkHook('font_asset')
        : const ToAppBundle(),
  );
}
