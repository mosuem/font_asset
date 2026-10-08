import 'package:hooks/hooks.dart';

import '../font_asset.dart';

/// A single font file belonging to a font family, used by [addFontFamily].
///
/// [filePath] is relative to the package root.
final class FontFile {
  const FontFile(this.filePath, {this.name, this.weight, this.style});

  /// Path of the font file, relative to the package root.
  final String filePath;

  /// The name under which the font is bundled, see [addFont]. Defaults to
  /// [filePath].
  final String? name;

  /// The font weight (`100`..`900`), or `null` for the default weight.
  final int? weight;

  /// The font style (`'normal'` or `'italic'`), or `null` for the default
  /// style.
  final String? style;
}

/// Adds a single font file at [filePath] (relative to the package root) to the
/// [output] as a [FontAsset] of the given [family].
///
/// The asset is registered under [name] (defaults to [filePath]) in the
/// package namespace, i.e. it is bundled as `packages/<package>/<name>`.
///
/// Does nothing when the SDK invoking the hook does not support font assets.
void addFont(
  BuildInput input,
  BuildOutputBuilder output, {
  required String family,
  required String filePath,
  String? name,
  int? weight,
  String? style,
  AssetRouting routing = const ToAppBundle(),
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
    routing: routing,
  );
}

/// Adds all [fonts] of a [family] to the [output].
///
/// Equivalent to calling [addFont] once per [FontFile].
void addFontFamily(
  BuildInput input,
  BuildOutputBuilder output, {
  required String family,
  required List<FontFile> fonts,
  AssetRouting routing = const ToAppBundle(),
}) {
  for (final font in fonts) {
    addFont(
      input,
      output,
      family: family,
      filePath: font.filePath,
      name: font.name,
      weight: font.weight,
      style: font.style,
      routing: routing,
    );
  }
}
