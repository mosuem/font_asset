import 'dart:io' show File, stdout;

import 'package:data_assets/data_assets.dart';
import 'package:font_subset/font_subset.dart'
    show fontSubsetExecutable, isSupportedFontFile, subsetFont;
import 'package:hooks/hooks.dart';
import 'package:record_use/record_use.dart';

import 'font_asset_base.dart';

/// Known icon font families that are subsetted to a single fallback glyph
/// when 0 icons from that family are recorded in the application.
const Map<String, int> _kKnownIconFontFallbackCodePoints = <String, int>{
  'MaterialIcons': 57415, // 0xe047, Icons.add
  'packages/cupertino_icons/CupertinoIcons': 62418, // 0xf3d2
};

const int _kSpaceCodePoint = 32;

/// Exception thrown when parsing recorded `IconData` usages or subsetting
/// fonts fails.
final class FontTreeShakeException implements Exception {
  const FontTreeShakeException(this.message);

  final String message;

  @override
  String toString() => 'FontTreeShakeException: $message';
}

/// Tree-shakes all [FontAsset]s in [input] using recorded `IconData` usages
/// from [LinkInput.recordedUses] and `package:font_subset`, emitting the
/// resulting [FontAsset]s to [output] with `ToAppBundle()` routing.
///
/// If [LinkInput.recordedUses] is `null` or empty, all input [FontAsset]s are
/// forwarded to [output] unchanged.
Future<void> treeShakeFontAssets(
  LinkInput input,
  LinkOutputBuilder output, {
  File? fontSubsetBinary,
}) async {
  final fonts = input.assets.fonts.toList();
  if (fonts.isEmpty) {
    return;
  }

  for (final font in fonts) {
    output.dependencies.add(font.file);
  }

  final Recordings? recordings;
  try {
    recordings = input.recordedUses;
  } on Object {
    output.assets.fonts.addAll(fonts);
    return;
  }

  if (recordings == null) {
    output.assets.fonts.addAll(fonts);
    return;
  }

  final iconDataByFamily = parseIconDataRecordings(recordings);
  final executable =
      fontSubsetBinary ?? await _resolveFontSubsetExecutable(input);

  for (var i = 0; i < fonts.length; i++) {
    final font = fonts[i];
    final inputFile = File.fromUri(font.file);
    if (!await isSupportedFontFile(inputFile)) {
      output.assets.fonts.add(font);
      continue;
    }

    final packageKey = 'packages/${font.package}/${font.family}';
    final recordedCodePoints =
        iconDataByFamily[packageKey] ?? iconDataByFamily[font.family];
    final fallbackCodePoint =
        _kKnownIconFontFallbackCodePoints[packageKey] ??
        _kKnownIconFontFallbackCodePoints[font.family];
    final codePoints =
        recordedCodePoints ??
        (fallbackCodePoint != null ? <int>[fallbackCodePoint] : null);

    if (codePoints == null || codePoints.isEmpty) {
      output.assets.fonts.add(font);
      continue;
    }

    final outputUri = input.outputDirectory.resolve(
      '${font.package}/${i}_${font.name.replaceAll('/', '_')}',
    );
    final outputFile = File.fromUri(outputUri);

    final result = await subsetFont(
      input: inputFile,
      output: outputFile,
      codePoints: codePoints,
      optionalCodePoints: const <int>[_kSpaceCodePoint],
      executable: executable,
    );
    stdout.writeln(result.summaryMessage);

    output.assets.fonts.add(
      FontAsset(
        file: outputFile.uri,
        family: font.family,
        name: font.name,
        package: font.package,
        weight: font.weight,
        style: font.style,
      ),
    );
  }
}

Future<File> _resolveFontSubsetExecutable(LinkInput input) async {
  if (input.config.buildDataAssets) {
    for (final dataAsset in input.assets.data) {
      if (dataAsset.name == 'font-subset') {
        final file = File.fromUri(dataAsset.file);
        if (file.existsSync()) {
          return file;
        }
      }
    }
  }
  return fontSubsetExecutable(cacheDirectory: input.outputDirectoryShared);
}

/// Extracts a mapping of font family keys (`<family>` or
/// `packages/<package>/<family>`) to the list of recorded `IconData` code
/// points from [recordings].
///
/// Throws a [FontTreeShakeException] if a non-constant `IconData` instance is
/// present in [recordings].
Map<String, List<int>> parseIconDataRecordings(Recordings recordings) {
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
          final family = fontPackage == null || fontPackage.isEmpty
              ? fontFamily
              : 'packages/$fontPackage/$fontFamily';
          (result[family] ??= <int>[]).add(codePoint);
        }
      }
    }
  }

  if (hasNonConstant) {
    throw const FontTreeShakeException(
      'This application cannot tree shake icon fonts because it has '
      'non-constant instances of IconData. Avoid non-constant invocations of '
      'IconData or build with --no-tree-shake-icons.',
    );
  }

  return result;
}

const String _iconDataClassName = 'IconData';
const String _codePointFieldName = 'codePoint';
const String _fontFamilyFieldName = 'fontFamily';
const String _fontPackageFieldName = 'fontPackage';

bool _isIconDataDefinition(DefinitionWithInstances definition) {
  if (definition is Class) {
    return definition.name == _iconDataClassName &&
        definition.library.uri == 'package:flutter/src/widgets/icon_data.dart';
  }
  final str = definition.toString();
  return str == 'package:flutter/src/widgets/icon_data.dart::IconData' ||
      str.startsWith('package:flutter/src/widgets/icon_data.dart::IconData.');
}

({Constant? codePoint, Constant? fontFamily, Constant? fontPackage})?
_extractIconDataConstants(InstanceReference reference) {
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
