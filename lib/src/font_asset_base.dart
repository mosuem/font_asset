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
}

extension FontAssetExt on EncodedAsset {
  bool get isFontAsset => type == fontAssetType;
}
