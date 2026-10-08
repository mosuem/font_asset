// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert' show utf8;
import 'dart:io' show File, Process;

import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as path;
import 'package:record_use/record_use.dart';

import 'font_asset.dart';

/// A class that wraps the functionality of recorded uses and the
/// font subset utility to tree shake unused icons from fonts.
class IconTreeShaker {
  /// Creates a wrapper for icon font subsetting.
  IconTreeShaker({
    required this.recordings,
    required this.fontSubset,
    required this.fonts,
    required this.isWeb,
  });

  /// The MIME types for supported font sets.
  static const kTtfMimeTypes = <String>{
    'font/ttf', // based on internet search
    'font/opentype',
    'font/otf',
    'application/x-font-opentype',
    'application/x-font-otf',
    'application/x-font-ttf', // based on running locally.
  };

  Future<void>? _iconDataProcessing;
  Map<String, _IconTreeShakerData>? _iconData;

  final Recordings? recordings;
  final File fontSubset;
  final List<FontAsset> fonts;
  final bool isWeb;

  // Fills the [_iconData] map.
  Future<void> _getIconData() async {
    final currentRecordings = recordings;
    if (currentRecordings == null) {
      _iconData = <String, _IconTreeShakerData>{};
      return;
    }

    final iconData = _parseRecordings(currentRecordings);

    final result = <String, _IconTreeShakerData>{};
    const kSpacePoint = 32;
    for (final entry in fonts) {
      final qualifiedFamily = 'packages/${entry.package}/${entry.family}';
      final codePoints = iconData[qualifiedFamily] ?? iconData[entry.family];
      if (codePoints == null) {
        continue;
      }

      // Add space as an optional code point, as web uses it to measure the font height.
      final optionalCodePoints = isWeb ? <int>[kSpacePoint] : <int>[];
      final filePath = entry.file.toFilePath();
      result[filePath] = _IconTreeShakerData(
        family: entry.family,
        relativePath: filePath,
        codePoints: codePoints,
        optionalCodePoints: optionalCodePoints,
      );
    }
    _iconData = result;
  }

  /// Calls font-subset, which transforms the [font] to a
  /// subsetted version at [outputPath].
  ///
  /// If the font is not recognized as an icon font used in the Flutter
  /// application, this returns null.
  Future<FontAsset?> subsetFont({
    required FontAsset font,
    required String outputPath,
  }) async {
    final input = File.fromUri(font.file);
    if (!input.existsSync() || input.lengthSync() < 12) {
      return null;
    }
    final mimeType = mime.lookupMimeType(
      input.path,
      headerBytes: await input.openRead(0, 12).first,
    );
    if (!kTtfMimeTypes.contains(mimeType)) {
      return null;
    }
    await (_iconDataProcessing ??= _getIconData());
    assert(_iconData != null);

    final iconTreeShakerData = _iconData![font.file.toFilePath()];
    if (iconTreeShakerData == null) {
      return null;
    }

    if (!fontSubset.existsSync()) {
      throw IconTreeShakerException._(
        'The font-subset utility is missing at ${fontSubset.path}. Run "flutter doctor".',
      );
    }

    final args = <String>[outputPath, input.path];
    final requiredCodePointStrings = iconTreeShakerData.codePoints.map(
      (int codePoint) => codePoint.toString(),
    );
    final optionalCodePointStrings = iconTreeShakerData.optionalCodePoints.map(
      (int codePoint) => 'optional:$codePoint',
    );
    final codePointsString = requiredCodePointStrings
        .followedBy(optionalCodePointStrings)
        .join(' ');
    print(
      'Running font-subset: ${fontSubset.path} ${args.join(' ')}, '
      'using codepoints $codePointsString',
    );
    final fontSubsetProcess = await Process.start(fontSubset.path, args);
    try {
      fontSubsetProcess.stdin.write(codePointsString);
      await fontSubsetProcess.stdin.flush();
      await fontSubsetProcess.stdin.close();
    } on Exception {
      // handled by checking the exit code.
    }

    final code = await fontSubsetProcess.exitCode;
    if (code != 0) {
      print(await utf8.decodeStream(fontSubsetProcess.stdout));
      print(await utf8.decodeStream(fontSubsetProcess.stderr));
      throw IconTreeShakerException._(
        'Font subsetting failed with exit code $code.',
      );
    }
    print(getSubsetSummaryMessage(input, File(outputPath)));
    return FontAsset(
      file: Uri.file(outputPath),
      name: font.name,
      weight: font.weight,
      style: font.style,
      family: font.family,
      package: font.package,
    );
  }

  String getSubsetSummaryMessage(File inputFont, File outputFont) {
    final fontName = path.basename(inputFont.path);
    final inputSize = inputFont.lengthSync().toDouble();
    final outputSize = outputFont.lengthSync().toDouble();
    final reductionBytes = inputSize - outputSize;
    final reductionPercentage = (reductionBytes / inputSize * 100)
        .toStringAsFixed(1);
    return 'Font asset "$fontName" was tree-shaken, reducing it from '
        '${inputSize.ceil()} to ${outputSize.ceil()} bytes '
        '($reductionPercentage% reduction). Tree-shaking can be disabled '
        'by providing the --no-tree-shake-icons flag when building your app.';
  }

  Map<String, List<int>> _parseRecordings(Recordings recordings) {
    final result = <String, List<int>>{};
    var hasNonConstant = false;

    for (final MapEntry(:key, :value) in recordings.instances.entries) {
      if (_isIconDataDefinition(key)) {
        for (final reference in value) {
          final constants = _extractIconDataConstants(reference);
          if (constants == null) {
            hasNonConstant = true;
            continue;
          }

          if (constants.codePoint is IntConstant) {
            final codePoint = (constants.codePoint! as IntConstant).value;
            if (constants.fontFamily is! StringConstant) {
              continue;
            }
            final fontFamily = (constants.fontFamily! as StringConstant).value;
            final fontPackage = constants.fontPackage is StringConstant
                ? (constants.fontPackage! as StringConstant).value
                : null;
            final familyKey = fontPackage == null
                ? fontFamily
                : 'packages/$fontPackage/$fontFamily';
            (result[familyKey] ??= <int>[]).add(codePoint);
          }
        }
      }
    }
    if (hasNonConstant) {
      throw IconTreeShakerException._(
        'This application cannot tree shake icon fonts because it has '
        'non-constant instances of IconData. Avoid non-constant invocations '
        'of IconData or try to build again with --no-tree-shake-icons.',
      );
    }
    return result;
  }

  static const String _iconDataClassName = 'IconData';
  static const String _codePointFieldName = 'codePoint';
  static const String _fontFamilyFieldName = 'fontFamily';
  static const String _fontPackageFieldName = 'fontPackage';

  bool _isIconDataDefinition(DefinitionWithInstances definition) {
    if (definition is Class) {
      return definition.name == _iconDataClassName &&
          definition.library.uri == 'package:flutter/src/widgets/icon_data.dart';
    }
    final str = definition.toString();
    return str == 'package:flutter/src/widgets/icon_data.dart::IconData' ||
        str.startsWith('package:flutter/src/widgets/icon_data.dart::IconData.');
  }

  _IconDataConstants? _extractIconDataConstants(InstanceReference reference) {
    if (reference case InstanceConstantReference(
      instanceConstant: InstanceConstant(:final fields),
    )) {
      return (
        codePoint: fields[_codePointFieldName],
        fontFamily: fields[_fontFamilyFieldName],
        fontPackage: fields[_fontPackageFieldName],
      );
    } else if (reference case InstanceCreationReference(
      positionalArguments: final positional,
      namedArguments: final named,
    )) {
      final hasNonConstantArg =
          positional.any((MaybeConstant arg) => arg is! Constant) ||
          named.values.any((MaybeConstant arg) => arg is! Constant);
      if (!hasNonConstantArg) {
        return (
          codePoint: positional.isNotEmpty ? positional[0] as Constant : null,
          fontFamily: named[_fontFamilyFieldName] as Constant?,
          fontPackage: named[_fontPackageFieldName] as Constant?,
        );
      }
    }
    return null;
  }
}

typedef _IconDataConstants = ({
  Constant? codePoint,
  Constant? fontFamily,
  Constant? fontPackage,
});

/// The font family name, relative path to font file, and list of code points
/// the application is using.
class _IconTreeShakerData {
  const _IconTreeShakerData({
    required this.family,
    required this.relativePath,
    required this.codePoints,
    required this.optionalCodePoints,
  });

  final String family;
  final String relativePath;
  final List<int> codePoints;
  final List<int> optionalCodePoints;

  @override
  String toString() => 'FontSubsetData($family, $relativePath, $codePoints)';
}

class IconTreeShakerException implements Exception {
  IconTreeShakerException._(this.message);

  final String message;

  @override
  String toString() =>
      'IconTreeShakerException: $message\n\n'
      'To disable icon tree shaking, pass --no-tree-shake-icons to the requested '
      'flutter build command';
}
