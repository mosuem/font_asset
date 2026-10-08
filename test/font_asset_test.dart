import 'dart:io';

import 'package:font_asset/font_asset.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('font_asset_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('FontAsset', () {
    test('encodes and decodes with all fields and preserves file URI', () {
      final fontFile = File('${tempDir.path}/Regular.ttf')
        ..writeAsStringSync('ttf');
      final asset = FontAsset(
        file: fontFile.uri,
        family: 'MyFamily',
        name: 'fonts/Regular.ttf',
        package: 'my_pkg',
        weight: 400,
        style: 'italic',
      );

      expect(asset.id, 'package:my_pkg/fonts/Regular.ttf');

      final encoded = asset.encode();
      expect(encoded.type, fontAssetType);
      expect(encoded.isFontAsset, isTrue);

      final decoded = encoded.asFontAsset;
      expect(decoded, equals(asset));
      expect(decoded.hashCode, equals(asset.hashCode));
      expect(decoded.file.toFilePath(), equals(fontFile.path));
      expect(decoded.family, 'MyFamily');
      expect(decoded.name, 'fonts/Regular.ttf');
      expect(decoded.package, 'my_pkg');
      expect(decoded.weight, 400);
      expect(decoded.style, 'italic');
    });

    test('name defaults to the file name', () {
      final asset = FontAsset(
        file: Uri.file('${tempDir.path}/fonts/Bold.ttf'),
        family: 'MyFamily',
        package: 'my_pkg',
      );
      expect(asset.name, 'Bold.ttf');
      expect(asset.weight, isNull);
      expect(asset.style, isNull);
    });
  });

  group('FontAssetsExtension', () {
    test('registers the font asset type on the build input', () {
      expect(
        _buildInput(tempDir, packageName: 'my_pkg').config.buildAssetTypes,
        contains(fontAssetType),
      );
      expect(
        _buildInput(
          tempDir,
          packageName: 'my_pkg',
          supportsFontAssets: false,
        ).config.buildAssetTypes,
        isNot(contains(fontAssetType)),
      );
    });

    test('validates application assets and lists outputFiles', () async {
      final ext = FontAssetsExtension();
      final fontFile = File('${tempDir.path}/Regular.ttf')
        ..writeAsStringSync('ttf');

      final validAsset = FontAsset(
        file: fontFile.uri,
        family: 'MyFamily',
        name: 'fonts/Regular.ttf',
        package: 'my_pkg',
        weight: 700,
        style: 'normal',
      );

      expect(
        await ext.validateApplicationAssets([validAsset.encode()]),
        isEmpty,
      );
      expect(ext.outputFiles([validAsset.encode()]).toList(), [fontFile.uri]);

      // Duplicate IDs should fail validation.
      final duplicateErrors = await ext.validateApplicationAssets([
        validAsset.encode(),
        validAsset.encode(),
      ]);
      expect(
        duplicateErrors,
        contains(
          contains(
            'Duplicate font asset id: "package:my_pkg/fonts/Regular.ttf"',
          ),
        ),
      );

      // Invalid weight and style and missing file should fail validation.
      final invalidAsset = FontAsset(
        file: Uri.file('${tempDir.path}/missing.ttf'),
        family: 'MyFamily',
        name: 'fonts/missing.ttf',
        package: 'my_pkg',
        weight: 450,
        style: 'oblique',
      );
      final fieldErrors = await ext.validateApplicationAssets([
        invalidAsset.encode(),
      ]);
      expect(fieldErrors, contains(contains('does not exist as a file')));
      expect(
        fieldErrors,
        contains(contains('must be a multiple of 100 between 100 and 900')),
      );
      expect(fieldErrors, contains(contains('must be "normal" or "italic"')));
    });

    test('rejects build output fonts owned by another package', () async {
      final fontFile = File('${tempDir.path}/Regular.ttf')
        ..writeAsStringSync('ttf');
      final input = _buildInput(tempDir, packageName: 'my_pkg');
      final output = BuildOutputBuilder();
      output.assets.fonts.add(
        FontAsset(file: fontFile.uri, family: 'F', package: 'other_pkg'),
      );
      final errors = await FontAssetsExtension().validateBuildOutput(
        input,
        output.build(),
      );
      expect(errors, contains(contains('must have package name my_pkg')));
    });
  });

  group('build helpers', () {
    test('addFont registers the file as asset and dependency', () {
      File('${tempDir.path}/fonts/Regular.ttf')
        ..createSync(recursive: true)
        ..writeAsStringSync('ttf');
      final input = _buildInput(tempDir, packageName: 'my_pkg');
      final outputBuilder = BuildOutputBuilder();

      addFont(
        input,
        outputBuilder,
        family: 'MyFamily',
        filePath: 'fonts/Regular.ttf',
        weight: 400,
        style: 'normal',
      );

      final output = outputBuilder.build();
      final fonts = output.assets.encodedAssets.map((e) => e.asFontAsset);
      expect(fonts, hasLength(1));
      final font = fonts.single;
      expect(font.package, 'my_pkg');
      expect(font.family, 'MyFamily');
      expect(font.name, 'fonts/Regular.ttf');
      expect(font.weight, 400);
      expect(font.style, 'normal');
      expect(
        font.file.toFilePath(),
        File('${tempDir.path}/fonts/Regular.ttf').path,
      );
      expect(output.dependencies, contains(font.file));
      expect(output.assets.encodedAssetsForLinking, isEmpty);
    });

    test('addFontFamily uses the relative path as name unless given', () {
      final input = _buildInput(tempDir, packageName: 'my_pkg');
      final outputBuilder = BuildOutputBuilder();

      addFontFamily(
        input,
        outputBuilder,
        family: 'Roboto',
        fonts: const [
          FontFile('fonts/Roboto-Regular.ttf'),
          FontFile('fonts/Roboto-Bold.ttf', weight: 700),
          FontFile(
            '../shared/Roboto-Italic.ttf',
            name: 'fonts/Roboto-Italic.ttf',
            style: 'italic',
          ),
        ],
      );

      final fonts = outputBuilder
          .build()
          .assets
          .encodedAssets
          .map((e) => e.asFontAsset)
          .toList();
      expect(fonts.map((f) => f.name), [
        'fonts/Roboto-Regular.ttf',
        'fonts/Roboto-Bold.ttf',
        'fonts/Roboto-Italic.ttf',
      ]);
      expect(fonts.map((f) => f.file), [
        input.packageRoot.resolve('fonts/Roboto-Regular.ttf'),
        input.packageRoot.resolve('fonts/Roboto-Bold.ttf'),
        input.packageRoot.resolve('../shared/Roboto-Italic.ttf'),
      ]);
      expect(fonts.map((f) => f.family).toSet(), {'Roboto'});
      expect(fonts.map((f) => f.weight), [null, 700, null]);
      expect(fonts.map((f) => f.style), [null, null, 'italic']);
    });

    test('helpers are no-ops when the SDK does not support font assets', () {
      final input = _buildInput(
        tempDir,
        packageName: 'my_pkg',
        supportsFontAssets: false,
      );
      final outputBuilder = BuildOutputBuilder();
      addFont(input, outputBuilder, family: 'F', filePath: 'fonts/a.ttf');
      addFontFamily(
        input,
        outputBuilder,
        family: 'F',
        fonts: const [FontFile('fonts/b.ttf')],
      );
      final output = outputBuilder.build();
      expect(output.assets.encodedAssets, isEmpty);
      expect(output.dependencies, isEmpty);
    });

    test('routing can send fonts to a link hook', () {
      final input = _buildInput(
        tempDir,
        packageName: 'my_pkg',
        linkingEnabled: true,
      );
      final outputBuilder = BuildOutputBuilder();
      addFont(
        input,
        outputBuilder,
        family: 'F',
        filePath: 'fonts/a.ttf',
        routing: const ToLinkHook('my_pkg'),
      );
      final output = outputBuilder.build();
      expect(output.assets.encodedAssets, isEmpty);
      expect(output.assets.encodedAssetsForLinking['my_pkg'], hasLength(1));
    });
  });
}

BuildInput _buildInput(
  Directory packageRoot, {
  required String packageName,
  bool linkingEnabled = false,
  bool supportsFontAssets = true,
}) {
  final builder = BuildInputBuilder()
    ..setupShared(
      packageName: packageName,
      packageRoot: packageRoot.uri,
      outputFile: packageRoot.uri.resolve('out/output.json'),
      outputDirectoryShared: packageRoot.uri.resolve('out/shared/'),
    )
    ..config.setupBuild(linkingEnabled: linkingEnabled);
  if (supportsFontAssets) {
    FontAssetsExtension().setupBuildInput(builder);
  }
  return builder.build();
}
