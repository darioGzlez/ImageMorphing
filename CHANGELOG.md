# Changelog

All notable changes are documented here. This project follows
[Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- Swift 6 language mode, strict-concurrency validation, and warnings-as-errors CI.
- `Image` initializers with optional explicit content identity.
- `Duration`, animation-curve, maximum-blur, and alpha-threshold configuration.
- iOS, macOS, tvOS, Mac Catalyst, and visionOS CI builds.
- Unit, lifecycle, performance, and visual rendering tests.
- DocC documentation and project maintenance templates.

### Changed

- Animation tasks now follow the SwiftUI view lifecycle and respect Reduce Motion.
- Durations and effect values are validated before use.
- The demo now supports both iOS and macOS.

### Fixed

- Removed the force unwrap when resolving Canvas symbols.
- Asset identities now include their bundle path.

## 1.0.0

- Initial upstream release by Jérémy Marchand.
