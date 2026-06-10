# Performance

`MorphingImage` uses a synchronous Canvas to keep rapidly changing symbols
consistent. The blur radius scales with the view and is capped by
`morphingImageMaximumBlurRadius(_:)`.

Profile grids and lists on representative devices before shipping many
simultaneous transitions. Measure Core Animation FPS, GPU utilization,
allocations, and peak memory with Instruments.
