import 'package:hooks/hooks.dart';

const fontAssetType = 'font_asset';

/// Represents a single font file.
class FontAsset {
  FontAsset({
    required this.file,
    required this.family,
    required this.package,
    this.weight,
  });

  factory FontAsset.fromEncoded(EncodedAsset encodedAsset) {
    final Map<String, Object?> encoding = encodedAsset.encoding;
    return FontAsset(
      file: Uri.parse(encoding[_fileKey]! as String),
      family: encoding[_familyKey]! as String,
      package: encoding[_packageKey]! as String,
      weight: encoding[_weightKey] as int?,
    );
  }

  final Uri file;
  final String family;
  final String package;
  final int? weight;

  static const _fileKey = 'file';
  static const _weightKey = 'weight';
  static const _familyKey = 'name';
  static const _packageKey = 'package';

  EncodedAsset encode() {
    return EncodedAsset(fontAssetType, {
      _fileKey: file.toFilePath(windows: false),
      _familyKey: family,
      _packageKey: package,
      if (weight != null) _weightKey: weight,
    });
  }

  @override
  String toString() {
    return 'FontAsset(file: $file, '
        'family: $family, '
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
  void add(FontAsset asset, {AssetRouting routing = const ToAppBundle()}) =>
      _output.addEncodedAsset(asset.encode(), routing: routing);

  /// Adds the given [assets] to the hook output with [routing].
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
  void add(FontAsset asset, {LinkAssetRouting routing = const ToAppBundle()}) =>
      _output.addEncodedAsset(asset.encode(), routing: routing);

  /// Adds the given [assets] to the hook output with [routing].
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
