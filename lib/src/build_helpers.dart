import 'package:flutter_hook_config/flutter_hook_config.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

import '../font_asset.dart';

void addFont(
  BuildInput input,
  BuildOutputBuilder output, {
  required String family,
  required String filePath,
  int? weight,
}) => output.assets.fonts.add(
  FontAsset(
    family: family,
    file: input.packageRoot.resolve(filePath),
    weight: weight,
    package: input.packageName,
  ),
  routing: input.config.linkingEnabled
      ? const ToLinkHook('font_asset')
      : const ToAppBundle(),
);

void addFontFamily(
  BuildInput input,
  BuildOutputBuilder output, {
  required String family,
  required List<({Uri filePath, int? weight})> fonts,
}) => output.assets.fonts.addAll(
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

void addMaterialFont(BuildInput input, BuildOutputBuilder output) =>
    output.assets.fonts.add(
      FontAsset(
        family: 'MaterialIcons',
        file: Uri.file(
          path.join(
            input.config.flutter.flutterRoot,
            'bin',
            'cache',
            'artifacts',
            'material_fonts',
            'MaterialIcons-Regular.otf',
          ),
        ),
        package: input.packageName,
      ),
      routing: input.config.linkingEnabled
          ? const ToLinkHook('font_asset')
          : const ToAppBundle(),
    );
