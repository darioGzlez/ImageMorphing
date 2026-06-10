# Migrating from 1.0.0

Keep existing asset, SF Symbol, and `Double` duration calls unchanged. The
maintained fork requires Xcode 16 and a Swift 6 toolchain, while retaining the
original iOS 15, macOS 12, and tvOS 15 deployment targets.

Use ``MorphingImage/init(image:id:)`` for existing images whose content changes.
Invalid durations now become zero-duration transitions, and Reduce Motion skips
the animation.
