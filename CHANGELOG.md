## 0.1.0

- **Breaking:** Upgrade to `hooks: ^2.0.0`.
- **Breaking:** Remove `hook/build.dart`, `hook/link.dart`, the bundled
  `font-subset` binary and `IconTreeShaker`. Fonts declared through this
  package are bundled by Flutter like fonts declared in `pubspec.yaml`, so
  Flutter's own icon tree shaker (`--tree-shake-icons`) applies to them.
- **Breaking:** Remove `addMaterialFont`; use `uses-material-design: true`.
- **Breaking:** `addFontFamily` now takes `List<FontFile>` with paths relative
  to the package root (like `addFont`) and supports `style`.
- Add `name`, `style`, `id`, `==`/`hashCode` to `FontAsset` and fix decoding of
  Windows file paths.
- Add input/output validation and `outputFiles` to `FontAssetsExtension`.
- Register font files as hook `dependencies` so builds rerun when they change.

## 0.0.9

- Allow for font families

## 0.0.8

- Get flutterRoot from config

## 0.0.7

- Remove appdill mention

## 0.0.6

- Add icon treeshaker from Flutter.

## 0.0.5

- Add icon treeshaker from Flutter.

## 0.0.4

- Add extension for build hook.

## 0.0.3

- Make weight optional.

## 0.0.2

- Add font asset class.

## 0.0.1

- Initial version.
