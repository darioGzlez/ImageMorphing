# ImageMorphing

ImageMorphing is a dependency-free SwiftUI package that morphs between template
images using blur and alpha-threshold effects.

This repository is a maintained fork of
[kodlian/ImageMorphing](https://github.com/kodlian/ImageMorphing). It preserves
the original MIT license and attribution to Jérémy Marchand.

https://user-images.githubusercontent.com/4249097/193521856-17ec03ea-4a33-481d-808b-0c21d142509b.mp4

## Requirements

- Swift 6.0 or newer
- Xcode 16.0 or newer

| Platform | Minimum |
| --- | --- |
| iOS | 15.0 |
| macOS | 12.0 |
| tvOS | 15.0 |
| Mac Catalyst | 15.0 |
| visionOS | 1.0 |

watchOS is not currently declared because it has not been verified. CI builds
all declared platforms and temporarily checks Swift 5 and Swift 6 language
modes with a Swift 6 toolchain.

Configuration uses a traditional `EnvironmentKey` instead of SwiftUI's newer
`@Entry` macro to preserve the deployment targets above.

## Installation

Add ImageMorphing in Xcode using Swift Package Manager, or add it to
`Package.swift`:

```swift
.package(url: "https://github.com/darioGzlez/ImageMorphing.git", from: "1.1.0")
```

Then add `ImageMorphing` to the target dependencies and import it:

```swift
import ImageMorphing
```

## Usage

Use an asset or SF Symbol:

```swift
MorphingImage("MyImage")
    .frame(width: 64, height: 64)

MorphingImage(systemName: "heart.fill")
    .foregroundStyle(.red)
    .frame(width: 64, height: 64)
    .accessibilityLabel("Favorite")
```

Use an existing `Image`. Provide an explicit identity when its content can
change:

```swift
MorphingImage(image: image, id: imageIdentifier)
    .frame(width: 64, height: 64)
```

The source image is always treated as a template. The result uses the current
`foregroundStyle`. Missing assets and unknown SF Symbols render as empty images,
matching SwiftUI's `Image` behavior.

## Configuration

All modifiers have defaults and can be combined:

```swift
MorphingImage(systemName: symbolName)
    .morphingImageDuration(1.5)
    .morphingImageAnimationCurve(.easeInOut)
    .morphingImageMaximumBlurRadius(20)
    .morphingImageBlurRadiusScale(0.05)
    .morphingImageAlphaThreshold(0.5)
```

On iOS 16, macOS 13, tvOS 16, visionOS 1, or newer, use `Duration`:

```swift
.morphingImageDuration(.seconds(1.5))
```

Negative and non-finite durations become zero. A zero duration displays the
final image immediately. Alpha thresholds are clamped to `0...1`. Increase the
blur radius scale for small images that need a stronger morphing effect:

```swift
MorphingImage(systemName: symbolName)
    .morphingImageBlurRadiusScale(0.3)
    .frame(width: 16, height: 16)
```

## Accessibility

ImageMorphing respects Reduce Motion and displays the final image without a
transition when it is enabled. Add an accessibility label that describes the
meaning of the image; the demo includes a complete example and supports Dynamic
Type.

## Lifecycle and performance

Animation work uses `.task(id:)`, is cancelled when the view disappears, and
restarts safely after rapid identity changes. `Canvas` renders synchronously to
avoid stale symbols.

Large views and many simultaneous transitions increase GPU and offscreen
rendering cost. See [PERFORMANCE.md](PERFORMANCE.md) for benchmarks, known
limits, and an Instruments checklist.

## Development

```bash
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
swift package diagnose-api-breaking-changes <baseline>
```

See [TESTING.md](TESTING.md), [MIGRATION.md](MIGRATION.md),
[CHANGELOG.md](CHANGELOG.md), and [CONTRIBUTING.md](CONTRIBUTING.md) for test,
release, and contribution details.

## License

ImageMorphing is available under the MIT license. See [LICENSE](LICENSE).
