import 'package:font_asset/src/tree_shaker.dart';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await link(args, (input, output) async {
    await treeShakeFontAssets(input, output);
  });
}
