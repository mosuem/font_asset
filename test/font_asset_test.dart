import 'dart:io';

import 'package:font_asset/font_asset.dart';
import 'package:font_asset/icon_treeshaker.dart';
import 'package:record_use/record_use.dart';
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

  test(
    'FontAsset encodes and decodes with all fields and preserves file URI',
    () {
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
    },
  );

  test(
    'FontAssetsExtension validates application assets and outputFiles',
    () async {
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
          contains('Duplicate font asset id: "package:my_pkg/fonts/Regular.ttf"'),
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
    },
  );

  test(
    'IconTreeShaker throws IconTreeShakerException on non-constant IconData',
    () async {
      final fontFile = File('${tempDir.path}/MaterialIcons-Regular.otf')
        ..writeAsBytesSync(const <int>[
          0,
          1,
          0,
          0,
          0,
          15,
          0,
          128,
          0,
          3,
          0,
          112,
        ]);
      final fontSubset = File('${tempDir.path}/font-subset')
        ..writeAsStringSync('');

      const iconDataClass = Class(
        'IconData',
        Library('package:flutter/src/widgets/icon_data.dart'),
      );
      const rootLoadingUnit = LoadingUnit('1');

      final recordings = Recordings(
        calls: const {},
        instances: {
          iconDataClass: const [
            InstanceCreationReference(
              definition: iconDataClass,
              loadingUnit: rootLoadingUnit,
              positionalArguments: [NonConstant()],
              namedArguments: {'fontFamily': StringConstant('MaterialIcons')},
            ),
          ],
        },
      );

      final fontAsset = FontAsset(
        file: fontFile.uri,
        family: 'MaterialIcons',
        name: 'fonts/MaterialIcons-Regular.otf',
        package: 'font_asset',
      );

      final shaker = IconTreeShaker(
        recordings: recordings,
        fontSubset: fontSubset,
        fonts: [fontAsset],
        isWeb: false,
      );

      await expectLater(
        shaker.subsetFont(
          font: fontAsset,
          outputPath: '${tempDir.path}/out.otf',
        ),
        throwsA(isA<IconTreeShakerException>()),
      );
    },
  );
}
