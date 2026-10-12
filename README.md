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

For icon fonts that should be tree-shaken based on recorded `IconData` usages
in release builds, pass `treeShake: true`:

```dart
addFont(
  input,
  output,
  family: 'MyIcons',
  filePath: 'fonts/MyIcons.otf',
  treeShake: true,
);
```

When `linkingEnabled` is `true`, `addFont(..., treeShake: true)` routes the
font to `package:font_asset`'s `hook/link.dart`, which subsets it using
[`package:font_subset`](https://pub.dev/packages/font_subset) and the compiler's
recorded `IconData` usages.

Fonts of a dependency package are available under the family name
`packages/<package>/<family>`, fonts of the app itself under `<family>`.

> **Experimental:** requires the Flutter data assets experiment
> (`flutter config --enable-dart-data-assets`).
