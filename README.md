### package:font_asset

A [`package:hooks`](https://pub.dev/packages/hooks) protocol extension that
lets a package declare font files from its `hook/build.dart` instead of the
`flutter:` `fonts:` section of `pubspec.yaml`.

Flutter bundles these fonts exactly like `pubspec.yaml` fonts: they are listed
in `FontManifest.json` (so the engine pre-registers them and no `FontLoader`
call is needed) and icon fonts are subsetted by Flutter's icon tree shaker in
release builds.

```dart
// hook/build.dart
import 'package:font_asset/font_asset.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) => build(args, (input, output) async {
  addFontFamily(
    input,
    output,
    family: 'Roboto',
    fonts: const [
      FontFile('fonts/Roboto-Regular.ttf'),
      FontFile('fonts/Roboto-Bold.ttf', weight: 700),
    ],
  );
});
```

Fonts of a dependency package are available under the family name
`packages/<package>/<family>`, fonts of the app itself under `<family>`.

> **Experimental:** requires the Flutter data assets experiment
> (`flutter config --enable-dart-data-assets`).
