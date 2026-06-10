# Performance

`MorphingImage` uses a synchronous SwiftUI `Canvas`, an alpha-threshold filter,
and a size-dependent blur capped at 20 points by default. Synchronous rendering
avoids stale symbols during rapid identity changes; asynchronous Canvas
rendering should be evaluated again only with representative app workloads.

## Known limits

- Large views and many simultaneous transitions increase offscreen-rendering and
  GPU cost.
- Rapid updates restart the lifecycle task and can keep the view continuously
  animating.
- Images should have simple template silhouettes. Detailed or multicolor images
  are not preserved.

## Automated benchmark

`MorphingImagePerformanceTests` measures construction of 1,000 configured views.
Run it with:

```bash
swift test --filter MorphingImagePerformanceTests
```

## Instruments checklist

Profile release builds on the oldest supported device class:

1. Animate one 128-point image, then grids containing 10, 50, and 100 images.
2. Record Core Animation FPS, GPU utilization, allocations, and peak memory.
3. Repeat with rapid identity changes and with Reduce Motion enabled.
4. Treat sustained frame drops or unbounded memory growth as release blockers.
