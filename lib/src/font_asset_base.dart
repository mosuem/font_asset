import 'package:hooks/hooks.dart';

const fontAssetType = 'font_asset';

class FontAsset {
  FontAsset({
    required this.file,
    required this.fontFamily,
    required this.package,
    this.weight,
  });
  factory FontAsset.fromEncoded(EncodedAsset encodedAsset) {
    final Map<String, Object?> encoding = encodedAsset.encoding;
    return FontAsset(
      file: Uri.parse(encoding[_fileKey]! as String),
      fontFamily: encoding[_fontFamilyKey]! as String,
      package: encoding[_packageKey]! as String,
      weight: encoding[_weightKey] as int?,
    );
  }

  final Uri file;
  final String fontFamily;
  final String package;
  final int? weight;

  static const _fileKey = 'file';
  static const _weightKey = 'weight';
  static const _fontFamilyKey = 'name';
  static const _packageKey = 'package';

  EncodedAsset encode() {
    return EncodedAsset(fontAssetType, {
      _fileKey: file.toFilePath(windows: false),
      _fontFamilyKey: fontFamily,
      _packageKey: package,
      if (weight != null) _weightKey: weight,
    });
  }

  @override
  String toString() {
    return 'FontAsset(file: $file, '
        'fontFamily: $fontFamily, '
        'package: $package, '
        'weight: $weight)';
  }
}

extension FontAssetExt on EncodedAsset {
  bool get isFontAsset => type == fontAssetType;
}

extension FontAssetAdder on BuildOutputAssetsBuilder {
  BuildOutputDataAssetsBuilder get fonts =>
      BuildOutputDataAssetsBuilder._(this);
}

extension LinkFontAssetAdder on LinkOutputAssetsBuilder {
  LinkOutputFontAssetsBuilder get fonts => LinkOutputFontAssetsBuilder._(this);
}

/// Extension on [BuildOutputBuilder] to add [FontAsset]s.
final class BuildOutputDataAssetsBuilder {
  final BuildOutputAssetsBuilder _output;

  BuildOutputDataAssetsBuilder._(this._output);

  /// Adds the given [asset] to the hook output with [routing].
  ///
  /// The [FontAsset.file] must be an absolute path. Prefer constructing the
  /// path via [HookInput.outputDirectoryShared] or [HookInput.outputDirectory]
  /// for files emitted during a hook, and via [HookInput.packageRoot] for files
  /// which are part of the package.
  void add(FontAsset asset, {AssetRouting routing = const ToAppBundle()}) =>
      _output.addEncodedAsset(asset.encode(), routing: routing);

  /// Adds the given [assets] to the hook output with [routing].
  ///
  /// The [FontAsset.file]s must be absolute paths. Prefer constructing the
  /// path via [HookInput.outputDirectoryShared] or [HookInput.outputDirectory]
  /// for files emitted during a hook, and via [HookInput.packageRoot] for files
  /// which are part of the package.
  void addAll(
    Iterable<FontAsset> assets, {
    AssetRouting routing = const ToAppBundle(),
  }) {
    for (final asset in assets) {
      add(asset, routing: routing);
    }
  }
}

/// Extension on [BuildOutputBuilder] to add [FontAsset]s.
final class LinkOutputFontAssetsBuilder {
  final LinkOutputAssetsBuilder _output;

  LinkOutputFontAssetsBuilder._(this._output);

  /// Adds the given [asset] to the hook output with [routing].
  ///
  /// The [FontAsset.file] must be an absolute path. Prefer constructing the
  /// path via [HookInput.outputDirectoryShared] or [HookInput.outputDirectory]
  /// for files emitted during a hook, and via [HookInput.packageRoot] for files
  /// which are part of the package.
  void add(FontAsset asset, {LinkAssetRouting routing = const ToAppBundle()}) =>
      _output.addEncodedAsset(asset.encode(), routing: routing);

  /// Adds the given [assets] to the hook output with [routing].
  ///
  /// The [FontAsset.file]s must be absolute paths. Prefer constructing the
  /// path via [HookInput.outputDirectoryShared] or [HookInput.outputDirectory]
  /// for files emitted during a hook, and via [HookInput.packageRoot] for files
  /// which are part of the package.
  void addAll(
    Iterable<FontAsset> assets, {
    LinkAssetRouting routing = const ToAppBundle(),
  }) {
    for (final asset in assets) {
      add(asset, routing: routing);
    }
  }
}

extension FontInputAssetsExt on LinkInputAssets {
  Iterable<FontAsset> get fonts =>
      encodedAssets.where((e) => e.isFontAsset).map(FontAsset.fromEncoded);
}
