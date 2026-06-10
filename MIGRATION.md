# Migrating from 1.0.0

Version 1.1 keeps the original asset, SF Symbol, and `Double` duration APIs.
Existing calls continue to compile:

```swift
MorphingImage(systemName: "heart.fill")
    .morphingImageDuration(1.5)
```

The package now requires a Swift 6 toolchain and Xcode 16 or newer. Deployment
targets remain iOS 15, macOS 12, and tvOS 15.

For an existing `Image`, provide an explicit identity whenever its content can
change:

```swift
MorphingImage(image: image, id: imageIdentifier)
```

On iOS 16, macOS 13, tvOS 16, visionOS 1, or newer, durations can use Swift's
`Duration` type:

```swift
.morphingImageDuration(.seconds(1.5))
```

Invalid durations that previously could trap or behave unpredictably now become
zero-duration transitions. Reduce Motion also displays the final image directly.
