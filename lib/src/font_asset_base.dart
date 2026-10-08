import 'package:hooks/hooks.dart';

const fontAssetType = 'font_asset';

/// Represents a single font file.
final class FontAsset {
  FontAsset({
    required this.file,
    required this.family,
    required this.package,
    String? name,
    this.weight,
    this.style,
  }) : name =
           name ??
           (file.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? family);

  factory FontAsset.fromEncoded(EncodedAsset encodedAsset) {
    assert(encodedAsset.isFontAsset);
    final encoding = encodedAsset.encoding;
    final fileStr = encoding[_fileKey]! as String;
    final file = fileStr.startsWith('file://')
        ? Uri.parse(fileStr)
        : Uri.file(fileStr);
    final name = encoding[_nameKey]! as String;
    final family = (encoding[_familyKey] as String?) ?? name;
    return FontAsset(
      file: file,
      name: name,
      family: family,
      package: encoding[_packageKey]! as String,
      weight: encoding[_weightKey] as int?,
      style: encoding[_styleKey] as String?,
    );
  }

  final Uri file;
  final String family;
  final String name;
  final String package;
  final int? weight;
  final String? style;

  /// The identifier for this font asset (`package:<package>/<name>`).
  String get id => 'package:$package/$name';

  static const _fileKey = 'file';
  static const _weightKey = 'weight';
  static const _styleKey = 'style';
  static const _familyKey = 'family';
  static const _nameKey = 'name';
  static const _packageKey = 'package';

  EncodedAsset encode() {
    return EncodedAsset(fontAssetType, {
      _fileKey: file.toFilePath(),
      _nameKey: name,
      _familyKey: family,
      _packageKey: package,
      if (weight != null) _weightKey: weight,
      if (style != null) _styleKey: style,
    });
  }

  @override
  bool operator ==(Object other) {
    if (other is! FontAsset) {
      return false;
    }
    return other.package == package &&
        other.name == name &&
        other.family == family &&
        other.weight == weight &&
        other.style == style &&
        other.file.toFilePath() == file.toFilePath();
  }

  @override
  int get hashCode =>
      Object.hash(package, name, family, weight, style, file.toFilePath());

  @override
  String toString() {
    return 'FontAsset(file: $file, '
        'name: $name, '
        'family: $family, '
        'package: $package, '
        'weight: $weight, '
        'style: $style)';
  }
}

extension FontAssetExt on EncodedAsset {
  bool get isFontAsset => type == fontAssetType;
  FontAsset get asFontAsset => FontAsset.fromEncoded(this);
}

extension FontAssetAdder on BuildOutputAssetsBuilder {
  BuildOutputFontAssetsBuilder get fonts =>
      BuildOutputFontAssetsBuilder._(this);
}

extension LinkFontAssetAdder on LinkOutputAssetsBuilder {
  LinkOutputFontAssetsBuilder get fonts => LinkOutputFontAssetsBuilder._(this);
}

typedef BuildOutputDataAssetsBuilder = BuildOutputFontAssetsBuilder;

/// Extension on [BuildOutputBuilder] to add [FontAsset]s.
final class BuildOutputFontAssetsBuilder {
  final BuildOutputAssetsBuilder _output;

  BuildOutputFontAssetsBuilder._(this._output);

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

/// Extension on [LinkOutputBuilder] to add [FontAsset]s.
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
