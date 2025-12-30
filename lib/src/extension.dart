import 'package:hooks/hooks.dart';

import 'font_asset_base.dart';

/// The protocol extension for the `hook/build.dart` and `hook/link.dart`
/// with [FontAsset]s.
final class FontAssetsExtension implements ProtocolExtension {
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
  Future<ValidationErrors> validateBuildInput(BuildInput input) async => [];

  @override
  Future<ValidationErrors> validateLinkInput(LinkInput input) async => [];

  @override
  Future<ValidationErrors> validateBuildOutput(
    BuildInput input,
    BuildOutput output,
  ) async => [];

  @override
  Future<ValidationErrors> validateLinkOutput(
    LinkInput input,
    LinkOutput output,
  ) async => [];

  @override
  Future<ValidationErrors> validateApplicationAssets(
    List<EncodedAsset> assets,
  ) async => [];
}
