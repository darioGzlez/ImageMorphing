# Contributing

Contributions should be small, tested, and compatible with the supported
deployment targets.

## Development setup

Use Xcode 16 or newer with a Swift 6 toolchain.

```bash
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
xcrun swift-format lint --strict --recursive Package.swift Sources Tests Demo/Demo
```

For UI changes, build the demo for iOS and macOS and verify Reduce Motion,
Dynamic Type, light mode, and dark mode.

## Pull requests

- Add focused tests for behavior changes.
- Document public API changes with DocC comments.
- Update `CHANGELOG.md` under `Unreleased`.
- Preserve the MIT license and original author attribution.
- Avoid external package dependencies unless the maintenance cost is justified.

## Versioning

This fork follows Semantic Versioning. Compatible additions and fixes ship in
minor or patch releases. Breaking API or deployment-target changes require a
major release. The planned first maintained release is `1.1.0`.
