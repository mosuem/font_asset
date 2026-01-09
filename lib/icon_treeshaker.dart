// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert' show json, utf8;
import 'dart:io' show File, Process;
import 'package:mime/mime.dart' as mime;

import 'package:path/path.dart' as path;

import 'font_asset.dart';
import 'src/font_asset_base.dart';

/// A class that wraps the functionality of the const finder package and the
/// font subset utility to tree shake unused icons from fonts.
class IconTreeShaker {
  /// Creates a wrapper for icon font subsetting.
  ///
  /// The constructor will validate the environment and print a warning if
  /// font subsetting has been requested in a debug build mode.
  IconTreeShaker({
    required this.appDill,
    required this.dart,
    required this.constFinder,
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

  final File appDill;
  final File dart;
  final File constFinder;
  final File fontSubset;
  final List<FontAsset> fonts;
  final bool isWeb;

  // Fills the [_iconData] map.
  Future<void> _getIconData() async {
    if (!appDill.existsSync()) {
      throw IconTreeShakerException._(
        'Expected to find kernel file at ${appDill.path}, but no file found.',
      );
    }

    final iconData = await _findConstants(dart, constFinder, appDill);
    final usedFonts = fonts
        .where((element) => iconData.keys.contains(element.family))
        .toList();
    if (usedFonts.length != iconData.length) {
      print(
        'Expected to find fonts for ${iconData.keys}, but found '
        '${usedFonts.map((e) => e.family).toList()}. This usually means you are referring to '
        'font families in an IconData class but not including them '
        'in the assets section of your pubspec.yaml, are missing '
        'the package that would include them, or are missing '
        '"uses-material-design: true".',
      );
    }

    final result = <String, _IconTreeShakerData>{};
    const kSpacePoint = 32;
    for (final entry in usedFonts) {
      final codePoints = iconData[entry.family];
      if (codePoints == null) {
        throw IconTreeShakerException._(
          'Expected to find code points for ${entry.family}, but none were found in $iconData.',
        );
      }

      // Add space as an optional code point, as web uses it to measure the font height.
      final optionalCodePoints = isWeb ? <int>[kSpacePoint] : <int>[];
      result[entry.file.path] = _IconTreeShakerData(
        family: entry.family,
        relativePath: entry.file.path,
        codePoints: codePoints,
        optionalCodePoints: optionalCodePoints,
      );
    }
    _iconData = result;
  }

  /// Calls font-subset, which transforms the [font] to a
  /// subsetted version at [outputPath].
  ///
  /// If the relative path is not recognized as an icon
  /// font used in the Flutter application, this returns false.
  /// If the font-subset subprocess fails, it will throw.
  /// Otherwise, it will return true.
  Future<FontAsset?> subsetFont({
    required FontAsset font,
    required String outputPath,
  }) async {
    final input = File.fromUri(font.file);
    if (input.lengthSync() < 12) {
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

    final iconTreeShakerData = _iconData![font.file.path];
    if (iconTreeShakerData == null) {
      return null;
    }

    if (!fontSubset.existsSync()) {
      throw IconTreeShakerException._(
        'The font-subset utility is missing. Run "flutter doctor".',
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
      weight: font.weight,
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

  Future<Map<String, List<int>>> _findConstants(
    File dart,
    File constFinder,
    File appDill,
  ) async {
    final args = <String>[
      constFinder.path,
      '--kernel-file',
      appDill.path,
      '--class-library-uri',
      'package:flutter/src/widgets/icon_data.dart',
      '--class-name',
      'IconData',
      '--annotation-class-name',
      '_StaticIconProvider',
      '--annotation-class-library-uri',
      'package:flutter/src/widgets/icon_data.dart',
    ];
    print('Running command: ${dart.path} ${args.join(' ')}');
    final constFinderProcessResult = await Process.run(dart.path, args);

    if (constFinderProcessResult.exitCode != 0) {
      throw IconTreeShakerException._(
        'ConstFinder failure: ${constFinderProcessResult.stderr}',
      );
    }
    final Object? constFinderMap = json.decode(
      constFinderProcessResult.stdout as String,
    );
    if (constFinderMap is! Map<String, Object?>) {
      throw IconTreeShakerException._(
        'Invalid ConstFinder output: expected a top level JSON object, '
        'got $constFinderMap.',
      );
    }
    final constFinderResult = _ConstFinderResult(constFinderMap);
    if (constFinderResult.hasNonConstantLocations) {
      print(
        'This application cannot tree shake icons fonts. '
        'It has non-constant instances of IconData at the '
        'following locations:',
      );
      for (final location in constFinderResult.nonConstantLocations) {
        print(
          '- ${location['file']}:${location['line']}:${location['column']}',
        );
      }
      throw IconTreeShakerException._(
        'Avoid non-constant invocations of IconData or try to '
        'build again with --no-tree-shake-icons.',
      );
    }
    return _parseConstFinderResult(constFinderResult);
  }

  Map<String, List<int>> _parseConstFinderResult(_ConstFinderResult constants) {
    final result = <String, List<int>>{};
    for (final iconDataMap in constants.constantInstances) {
      final package = iconDataMap['fontPackage'];
      final fontFamily = iconDataMap['fontFamily'];
      final codePoint = iconDataMap['codePoint'];
      if ((package ?? '') is! String ||
          (fontFamily ?? '') is! String ||
          codePoint is! num) {
        throw IconTreeShakerException._(
          'Invalid ConstFinder result. Expected "fontPackage" to be a String, '
          '"fontFamily" to be a String, and "codePoint" to be an int, '
          'got: $iconDataMap.',
        );
      }
      if (fontFamily == null) {
        print(
          'Expected to find fontFamily for constant IconData with codepoint: '
          '$codePoint, but found fontFamily: $iconDataMap. This usually means '
          'you are relying on the system font. Alternatively, font families in '
          'an IconData class can be provided in the assets section of your '
          'pubspec.yaml, or you are missing "uses-material-design: true".',
        );
        continue;
      }
      final family = fontFamily as String;
      final key = package == null ? family : 'packages/$package/$family';
      result[key] ??= <int>[];
      result[key]!.add(codePoint.round());
    }
    return result;
  }
}

class _ConstFinderResult {
  _ConstFinderResult(this.result);

  final Map<String, Object?> result;

  late final List<Map<String, Object?>> constantInstances = _getList(
    result['constantInstances'],
    'Invalid ConstFinder output: Expected "constInstances" to be a list of objects.',
  );

  late final List<Map<String, Object?>> nonConstantLocations = _getList(
    result['nonConstantLocations'],
    'Invalid ConstFinder output: Expected "nonConstLocations" to be a list of objects',
  );

  bool get hasNonConstantLocations => nonConstantLocations.isNotEmpty;
}

/// The font family name, relative path to font file, and list of code points
/// the application is using.
class _IconTreeShakerData {
  /// All parameters are required.
  const _IconTreeShakerData({
    required this.family,
    required this.relativePath,
    required this.codePoints,
    required this.optionalCodePoints,
  });

  /// The font family name, e.g. "MaterialIcons".
  final String family;

  /// The relative path to the font file.
  final String relativePath;

  /// The list of code points for the font.
  final List<int> codePoints;

  /// The list of code points to be optionally added, if they exist in the
  /// input font. Otherwise, the tool will silently omit them.
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

List<Map<String, Object?>> _getList(Object? object, String errorMessage) {
  if (object is List<Object?>) {
    return object.cast<Map<String, Object?>>();
  }
  throw IconTreeShakerException._(errorMessage);
}
