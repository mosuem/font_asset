import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

import '../font_asset.dart';

void addFontAsset(
  BuildInput input,
  BuildOutputBuilder output, {
  required String filePath,
  required String fontFamily,
}) => output.assets.fonts.add(
  FontAsset(
    file: input.packageRoot.resolve(filePath),
    fontFamily: fontFamily,
    package: input.packageName,
  ),
  routing: input.config.linkingEnabled
      ? const ToLinkHook('font_asset')
      : const ToAppBundle(),
);
final flutterRoot = '/home/mosum/projects/flutter/';

void addMaterialFont(BuildInput input, BuildOutputBuilder output) =>
    output.assets.fonts.add(
      FontAsset(
        file: Uri.file(
          path.join(
            flutterRoot,
            'bin',
            'cache',
            'artifacts',
            'material_fonts',
            'MaterialIcons-Regular.otf',
          ),
        ),
        fontFamily: 'MaterialIcons',
        package: input.packageName,
      ),
      routing: input.config.linkingEnabled
          ? const ToLinkHook('font_asset')
          : const ToAppBundle(),
    );
