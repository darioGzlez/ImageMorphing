# Testing strategy

ImageMorphing keeps its automated suite dependency-free and focused on public
behavior, lifecycle decisions, and rendering regressions.

## Automated coverage

| Area | Test type | Cases |
| --- | --- | --- |
| Configuration | Unit | Zero, negative, non-finite, clamped, and `Duration` values |
| Sources | Unit | Assets, bundle identities, SF Symbols, `Image`, and explicit IDs |
| Lifecycle | Unit/async | Initial display, rapid changes, Reduce Motion, and cancellation |
| Layout | Unit | Zero, tiny, large, negative, and non-finite sizes |
| Rendering | Visual smoke | Foreground-style changes produce different non-empty images |
| Performance | Benchmark | Construction of 1,000 configured views |
| Platforms | Build matrix | iOS, macOS, tvOS, Mac Catalyst, and visionOS |

Run the required checks with:

```bash
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
xcrun swift-format lint --strict --recursive Package.swift Sources Tests Demo/Demo
```

## Manual release checks

- Exercise rapid repeated transitions in the iOS and macOS demo.
- Verify Reduce Motion, Dynamic Type, light mode, dark mode, and VoiceOver.
- Profile lists and grids with Instruments using the checklist in
  `PERFORMANCE.md`.
- Review the demo video when the transition appearance changes.

## Remaining gaps

Pixel-exact snapshots are intentionally not used because SF Symbol rendering
changes between OS versions. The visual smoke test catches empty output and
foreground-style regressions without creating unstable baselines. GPU and
memory thresholds remain device-specific and require Instruments.
