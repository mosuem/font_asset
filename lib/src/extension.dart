import 'dart:io';

import 'package:hooks/hooks.dart';

import 'font_asset_base.dart';

/// The protocol extension for the `hook/build.dart` and `hook/link.dart`
/// with [FontAsset]s.
final class FontAssetsExtension extends ProtocolExtension {
  FontAssetsExtension();

  @override
  void setupBuildInput(BuildInputBuilder input) {
    _setupConfig(input);
  }

  @override
  void setupLinkInput(LinkInputBuilder input) {
    _setupConfig(input);
  }

  void _setupConfig(HookInputBuilder input) {
    input.config.addBuildAssetTypes([fontAssetType]);
  }

  @override
  Future<ValidationErrors> validateBuildInput(BuildInput input) async =>
      _validateHookInput([
        for (final assets in input.assets.encodedAssets.values) ...assets,
      ]);

  @override
  Future<ValidationErrors> validateLinkInput(LinkInput input) async =>
      _validateHookInput(input.assets.encodedAssets);

  @override
  Future<ValidationErrors> validateBuildOutput(
    BuildInput input,
    BuildOutput output,
  ) async => _validateBuildOrLinkOutput(input, [
    ...output.assets.encodedAssets,
    ...output.assets.encodedAssetsForBuild,
    for (final assetList in output.assets.encodedAssetsForLinking.values)
      ...assetList,
  ], isBuild: true);

  @override
  Future<ValidationErrors> validateLinkOutput(
    LinkInput input,
    LinkOutput output,
  ) async => _validateBuildOrLinkOutput(
    input,
    output.assets.encodedAssets,
    isBuild: false,
  );

  @override
  Future<ValidationErrors> validateApplicationAssets(
    List<EncodedAsset> assets,
  ) async {
    final errors = <String>[];
    final ids = <String>{};
    for (final asset in assets) {
      if (!asset.isFontAsset) continue;
      final fontAsset = FontAsset.fromEncoded(asset);
      if (!ids.add(fontAsset.id)) {
        errors.add('Duplicate font asset id: "${fontAsset.id}".');
      }
      errors.addAll(_validateFontAssetFields(fontAsset));
    }
    return errors;
  }

  @override
  Iterable<Uri> outputFiles(List<EncodedAsset> assets) sync* {
    for (final encodedAsset in assets) {
      if (encodedAsset.isFontAsset) {
        yield encodedAsset.asFontAsset.file;
      }
    }
  }

  List<String> _validateHookInput(List<EncodedAsset> assets) {
    final errors = <String>[];
    for (final asset in assets) {
      if (!asset.isFontAsset) continue;
      final fontAsset = FontAsset.fromEncoded(asset);
      errors.addAll(_validateFontAssetFields(fontAsset));
    }
    return errors;
  }

  List<String> _validateBuildOrLinkOutput(
    HookInput input,
    List<EncodedAsset> encodedAssets, {
    required bool isBuild,
  }) {
    final errors = <String>[];
    final ids = <String>{};
    for (final asset in encodedAssets) {
      if (!asset.isFontAsset) continue;
      final fontAsset = FontAsset.fromEncoded(asset);
      if (isBuild && fontAsset.package != input.packageName) {
        errors.add('Font asset must have package name ${input.packageName}');
      }
      if (!ids.add(fontAsset.id)) {
        errors.add(
          'More than one font asset with same "${fontAsset.name}" name.',
        );
      }
      errors.addAll(_validateFontAssetFields(fontAsset));
    }
    return errors;
  }

  List<String> _validateFontAssetFields(FontAsset fontAsset) {
    final errors = <String>[];
    final file = fontAsset.file;
    if (!file.isAbsolute) {
      errors.add(
        'Font asset "${fontAsset.id}" file (${file.toFilePath()}) '
        'must be an absolute path.',
      );
    } else if (!File.fromUri(file).existsSync()) {
      errors.add(
        'Font asset "${fontAsset.id}" file (${file.toFilePath()}) '
        'does not exist as a file.',
      );
    }
    final weight = fontAsset.weight;
    if (weight != null && (weight < 100 || weight > 900 || weight % 100 != 0)) {
      errors.add(
        'Font asset "${fontAsset.id}" weight ($weight) '
        'must be a multiple of 100 between 100 and 900.',
      );
    }
    final style = fontAsset.style;
    if (style != null && style != 'normal' && style != 'italic') {
      errors.add(
        'Font asset "${fontAsset.id}" style ("$style") '
        'must be "normal" or "italic".',
      );
    }
    return errors;
  }
}
