import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.linkingEnabled || !input.config.buildDataAssets) {
      return;
    }
    final fontSubsetAssets = input.assets['font_subset'];
    for (final encoded in fontSubsetAssets) {
      if (encoded.isDataAsset) {
        final asset = encoded.asDataAsset;
        output.assets.data.add(
          DataAsset(
            package: input.packageName,
            name: asset.name,
            file: asset.file,
          ),
          routing: ToLinkHook(input.packageName),
        );
      }
    }
  });
}
