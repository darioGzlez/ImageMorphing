# ``ImageMorphing``

Create template-image transitions with SwiftUI blur and alpha-threshold effects.

## Overview

Use ``MorphingImage`` anywhere you would use a template `Image`. Changing its
identity starts a lifecycle-bound transition. The transition is cancelled when
the view disappears and is skipped when Reduce Motion is enabled.

```swift
MorphingImage(systemName: isFavorite ? "heart.fill" : "heart")
    .foregroundStyle(.red)
    .frame(width: 64, height: 64)
```

For existing images, provide an explicit identity when the content can change:

```swift
MorphingImage(image: image, id: imageIdentifier)
```

## Topics

### Creating Images

- ``MorphingImage``

### Configuring Transitions

- ``MorphingImageAnimationCurve``

Use `morphingImageDuration(_:)`, `morphingImageAnimationCurve(_:)`,
`morphingImageMaximumBlurRadius(_:)`, `morphingImageBlurRadiusScale(_:)`, and
`morphingImageAlphaThreshold(_:)` to configure a transition.

### Guides

- <doc:Migration>
- <doc:Performance>
