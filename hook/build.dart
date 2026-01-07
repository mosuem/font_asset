import 'package:data_assets/data_assets.dart';
import 'package:flutter_hook_config/flutter_hook_config.dart'
    show BuildConfigExtension;
import 'package:hooks/hooks.dart';

void main(List<String> arguments) {
  build(arguments, (input, output) async {
    output.assets.data.addAll([
      DataAsset(
        file: input.packageRoot.resolve('binaries/const_finder.dart.snapshot'),
        name: 'const_finder',
        package: input.packageName,
      ),
      DataAsset(
        file: input.packageRoot.resolve('binaries/font-subset'),
        name: 'font-subset',
        package: input.packageName,
      ),
      DataAsset(
        file: input.config.flutter.appDill,
        name: 'appDill',
        package: input.packageName,
      ),
    ], routing: ToLinkHook(input.packageName));
  });
}
