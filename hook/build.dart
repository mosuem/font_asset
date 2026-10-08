import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as path;

Uri _resolveFontSubset(BuildInput input) {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final hostDir = switch (Abi.current()) {
    Abi.linuxArm64 => 'linux-arm64',
    Abi.linuxX64 => 'linux-x64',
    Abi.macosArm64 || Abi.macosX64 => 'darwin-x64',
    Abi.windowsArm64 => 'windows-arm64',
    Abi.windowsX64 => 'windows-x64',
    _ => 'linux-x64',
  };
  final binaryName = Platform.isWindows ? 'font-subset.exe' : 'font-subset';
  final sdkFontSubset = File(
    path.join(
      flutterRoot,
      'bin',
      'cache',
      'artifacts',
      'engine',
      hostDir,
      binaryName,
    ),
  );
  if (sdkFontSubset.existsSync()) {
    return sdkFontSubset.uri;
  }
  return input.packageRoot.resolve('binaries/font-subset');
}

void main(List<String> arguments) {
  build(arguments, (input, output) async {
    if (!input.config.linkingEnabled || !input.config.buildDataAssets) {
      return;
    }
    final fontSubset = _resolveFontSubset(input);
    output.dependencies.add(fontSubset);
    output.assets.data.add(
      DataAsset(
        file: fontSubset,
        name: 'font-subset',
        package: input.packageName,
      ),
      routing: ToLinkHook(input.packageName),
    );
  });
}
