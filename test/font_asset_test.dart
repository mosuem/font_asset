import 'dart:convert' show base64Decode, json;
import 'dart:io';

import 'package:font_asset/font_asset.dart';
import 'package:hooks/hooks.dart';
import 'package:record_use/record_use.dart';
import 'package:test/test.dart';

/// Roboto Regular subset containing the three glyphs `h` (104), `k` (107),
/// and `o` (111).
const String _kRobotoThreeGlyphFontBase64 =
    'AAEAAAAPAIAAAwBwT1MvMnRvghoAAAJoAAAAYGNtYXAAfwFBAAAB0AAAAERj'
    'dnQgK6gHnQAAAhQAAABUZnBnbXf4YKsAAAUoAAABvGdhc3AACAATAAABCAAA'
    'AAxnbHlmm9QWxQAABuQAAAHYaGRteA4KBA4AAAEUAAAAEGhlYWT8atJ6AAAB'
    'mAAAADZoaGVhCroFpAAAAXQAAAAkaG10eBCSAdgAAAEkAAAAEGxvY2EBMgCd'
    'AAAA/AAAAAptYXhwAjQDCQAAATQAAAAgbmFtZRIELQQAAALIAAABFHBvc3T/'
    'bQBkAAABVAAAACBwcmVwomb6yQAAA9wAAAFJAAAAAABGAJ0A7AAAAAEAAgAI'
    'AAL//wAPAAAAAQAAAAgJBQQFBQUAAAOMAGQEaACMBA4AjQSQAFsAAQAAAAQA'
    'jwAWAFQABQABAAAAAAAOAAACAAIkAAYAAQADAAAAAAAA/2oAZAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAEAAAds/gwAAAlJ+hv+SgkwAAEAAAAAAAAAAAAAAAAA'
    'AAAEAAEAAAACIxJ4oEfFXw889QAZCAAAAAAAxPARLgAAAADVAVL0+hv91Qkw'
    'CHMAAAAJAAIAAAAAAAAAAAACAAAAAwAAABQAAwABAAAAFAAEADAAAAAIAAgA'
    'AgAAAGgAawBv//8AAABoAGsAb////5n/l/+UAAEAAAAAAAAAAAAqAJ0AgACK'
    'AHgA1ABkAE4AWgCHAGAAVgA0AjwAvACyAI4AxAAAABT+YAAUApsAIAMhAAsE'
    'OgAUBI0AEAWwABQGGAAVAaYAEQbAAA4G2QAGAAAAAAADBIYBkAAFAAAFmgUz'
    'AAABHwWaBTMAAAPRAGYCAAAAAgAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAABH'
    'T09HAEAAaABvBgD+AABmB5oCACAAAZ8AAAAABDoFsAAgACAAAwAAAAcAWgAD'
    'AAEECQAAAF4AXAADAAEECQABAAwAUAADAAEECQACAA4AQgADAAEECQADAAwA'
    'UAADAAEECQAEAAwAUAADAAEECQAFACYAHAADAAEECQAGABwAAABSAG8AYgBv'
    'AHQAbwAtAFIAZQBnAHUAbABhAHIAVgBlAHIAcwBpAG8AbgAgADIALgAxADMA'
    'NwA7ACAAMgAwADEANwBSAGUAZwB1AGwAYQByAFIAbwBiAG8AdABvAEMAbwBw'
    'AHkAcgBpAGcAaAB0ACAAMgAwADEAMQAgAEcAbwBvAGcAbABlACAASQBuAGMA'
    'LgAgAEEAbABsACAAUgBpAGcAaAB0AHMAIABSAGUAcwBlAHIAdgBlAGQALrAM'
    'K7AAKwCyARACKwGyEQECKwG3ETowJRsQAAgrALcBSDsuIRQACCu3AlhIOCgU'
    'AAgrtwNSQzQlFgAIK7cEXk08KxkACCu3BTYsIhkPAAgrtwZxXUYyGwAIK7cH'
    'kXdcOiMACCu3CH5nUDkaAAgrtwlURTYmFAAIK7cKdmBLNh0ACCu3C4NkTjoj'
    'AAgrtwzZsopjPAAIK7cNFBAMCQYACCu3DjwyJxwRAAgrtw9ANCkdFAAIK7cQ'
    'UEEuIRQACCsAshILByuwACBFfWkYRLI/GgFzsl8aAXOyfxoBc7IvGgF0sk8a'
    'AXSybxoBdLKPGgF0sq8aAXSy/xoBdLIfGgF1sj8aAXWyXxoBdbJ/GgF1sg8e'
    'AXOyfx4Bc7LvHgFzsh8eAXSyXx4BdLKPHgF0ss8eAXSy/x4BdLI/HgF1sm8e'
    'AXWyLyABc7JvIAFzAAAAsAAsS7AJUFixAQGOWbgB/4WwhB2xCQNfXi2wASwg'
    'IEVpRLABYC2wAiywASohLbADLCBGsAMlRlJYI1kgiiCKSWSKIEYgaGFksAQl'
    'RiBoYWRSWCNlilkvILAAU1hpILAAVFghsEBZG2kgsABUWCGwQGVZWTotsAQs'
    'IEawBCVGUlgjilkgRiBqYWSwBCVGIGphZFJYI4pZL/0tsAUsSyCwAyZQWFFY'
    'sIBEG7BARFkbISEgRbDAUFiwwEQbIVlZLbAGLCAgRWlEsAFgICBFfWkYRLAB'
    'YC2wByywBiotsAgsSyCwAyZTWLBAG7AAWYqKILADJlNYIyGwgIqKG4ojWSCw'
    'AyZTWCMhsMCKihuKI1kgsAMmU1gjIbgBAIqKG4ojWSCwAyZTWCMhuAFAioob'
    'iiNZILADJlNYsAMlRbgBgFBYIyG4AYAjIRuwAyVFIyEjIVkbIVlELbAJLEtT'
    'WEVEGyEhWS2wCiywKEUtsAsssClFLbAMLLEnAYggilNYuUAABABjuAgAiFRY'
    'uQAoA+hwWRuwI1NYsCCIuBAAVFi5ACgD6HBZWVktsA0ssECIuCAAWlixKQBE'
    'G7kAKQPoRFktAAEAjAAAA98GAAARAEqyChITERI5ALAQL7AARViwAi8bsQIa'
    'PlmwAEVYsAUvG7EFEj5ZsABFWLAOLxuxDhI+WbIAAgUREjmwAhCxCgGwCitY'
    'Idgb9FkwMQE2MyATESMRJiYjIgYHESMRMwFFe8UBVwO5AWlvWogmubkDt5f+'
    'ff01Asx1cGBO/P0GAAAAAQCNAAAEDAYAAAwAdQCwAEVYsAQvG7EEID5ZsABF'
    'WLAILxuxCBo+WbAARViwAi8bsQISPlmwAEVYsAsvG7ELEj5ZsgAIAhESOUAV'
    'OgBKAFoAagB6AIoAmgCqALoAygAKXbIGCAIREjlAFTYGRgZWBmYGdgaGBpYG'
    'pga2BsYGCl0wMQEHESMRMxE3ATMBASMBunS5uWMBUeH+WwHW2QH1ef6EBgD8'
    'X3cBZP48/YoAAgBb/+wENAROAA8AGwBFsgwcHRESObAMELAT0ACwAEVYsAQv'
    'G7EEGj5ZsABFWLAMLxuxDBI+WbETAbAKK1gh2Bv0WbAEELEZAbAKK1gh2Bv0'
    'WTAxEzQ2NjMyABUVFAYGIyIANRcUFjMyNjU0JiMiBlt934/dARF54ZLc/u+6'
    'p4yNpqmMiagCJ5/+iv7O/g2e+4wBMvwJtNrdx7Ld2g==';

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
      final fontFile = File.fromUri(tempDir.uri.resolve('Regular.ttf'))
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
        File.fromUri(tempDir.uri.resolve('fonts/Regular.ttf')).path,
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

    test(
      'treeShake routes fonts to font_asset link hook when linkingEnabled',
      () {
        final linkingInput = _buildInput(
          tempDir,
          packageName: 'my_pkg',
          linkingEnabled: true,
        );
        final linkingOutput = BuildOutputBuilder();
        addFont(
          linkingInput,
          linkingOutput,
          family: 'MyIcons',
          filePath: 'fonts/MyIcons.ttf',
          treeShake: true,
        );
        final builtLinking = linkingOutput.build();
        expect(builtLinking.assets.encodedAssets, isEmpty);
        expect(
          builtLinking.assets.encodedAssetsForLinking['font_asset'],
          hasLength(1),
        );

        final debugInput = _buildInput(
          tempDir,
          packageName: 'my_pkg',
          linkingEnabled: false,
        );
        final debugOutput = BuildOutputBuilder();
        addFont(
          debugInput,
          debugOutput,
          family: 'MyIcons',
          filePath: 'fonts/MyIcons.ttf',
          treeShake: true,
        );
        final builtDebug = debugOutput.build();
        expect(builtDebug.assets.encodedAssets, hasLength(1));
        expect(builtDebug.assets.encodedAssetsForLinking, isEmpty);
      },
    );
  });

  group('treeShakeFontAssets', () {
    test('subsets icon font based on recorded IconData usages', () async {
      final fontFile = File('${tempDir.path}/MyIcons.ttf')
        ..writeAsBytesSync(base64Decode(_kRobotoThreeGlyphFontBase64));

      const iconDataClass = Class(
        'IconData',
        Library('package:flutter/src/widgets/icon_data.dart'),
      );
      final recordedUsesFile = File('${tempDir.path}/recorded_uses.json')
        ..writeAsStringSync(
          json.encode(
            Recordings(
              calls: const <DefinitionWithStaticCalls, List<CallReference>>{},
              instances: <DefinitionWithInstances, List<InstanceReference>>{
                iconDataClass: const <InstanceReference>[
                  InstanceConstantReference(
                    instanceConstant: InstanceConstant(
                      definition: iconDataClass,
                      fields: <String, Constant>{
                        'codePoint': IntConstant(104), // 'h'
                        'fontFamily': StringConstant('MyIcons'),
                        'fontPackage': StringConstant('my_pkg'),
                      },
                    ),
                    loadingUnit: LoadingUnit('root'),
                  ),
                ],
              },
            ).toJson(),
          ),
        );

      final linkInputBuilder = LinkInputBuilder()
        ..setupShared(
          packageName: 'font_asset',
          packageRoot: tempDir.uri,
          outputFile: tempDir.uri.resolve('out/link_output.json'),
          outputDirectoryShared: tempDir.uri.resolve('out/shared/'),
        )
        ..setupLink(
          assets: <EncodedAsset>[
            FontAsset(
              file: fontFile.uri,
              family: 'MyIcons',
              name: 'fonts/MyIcons.ttf',
              package: 'my_pkg',
            ).encode(),
          ],
          assetsFromLinking: const <EncodedAsset>[],
          recordedUsesFile: recordedUsesFile.uri,
        );
      FontAssetsExtension().setupLinkInput(linkInputBuilder);
      final linkInput = linkInputBuilder.build();

      final linkOutputBuilder = LinkOutputBuilder();
      await treeShakeFontAssets(linkInput, linkOutputBuilder);

      final linkOutput = linkOutputBuilder.build();
      final outputFonts = linkOutput.assets.encodedAssets
          .map((e) => e.asFontAsset)
          .toList();
      expect(outputFonts, hasLength(1));
      final shakenFont = outputFonts.single;
      expect(shakenFont.family, 'MyIcons');
      expect(shakenFont.name, 'fonts/MyIcons.ttf');
      expect(shakenFont.package, 'my_pkg');

      final shakenFile = File.fromUri(shakenFont.file);
      expect(shakenFile.existsSync(), isTrue);
      expect(shakenFile.lengthSync(), lessThan(fontFile.lengthSync()));
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
