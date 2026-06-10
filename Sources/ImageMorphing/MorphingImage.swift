//
//  MorphingImage.swift
//  ImageMorphing
//
//  Created by Jeremy Marchand on 01/10/2022.
//

import Dispatch
import Foundation
import SwiftUI

/// The timing curve used by a ``MorphingImage`` transition.
public enum MorphingImageAnimationCurve: Hashable, Sendable {
  /// Starts slowly and finishes slowly.
  case easeInOut

  /// Starts slowly.
  case easeIn

  /// Finishes slowly.
  case easeOut

  /// Maintains a constant speed.
  case linear

  fileprivate func animation(duration: Double, phase: MorphingAnimationPhase) -> Animation {
    switch self {
    case .easeInOut:
      phase == .entering
        ? .easeIn(duration: duration)
        : .easeOut(duration: duration)
    case .easeIn:
      .easeIn(duration: duration)
    case .easeOut:
      .easeOut(duration: duration)
    case .linear:
      .linear(duration: duration)
    }
  }
}

/// An image that animates when its identity changes.
///
/// `MorphingImage` combines a blur and an alpha-threshold effect. Source
/// images are rendered as templates, so the resulting image uses the current
/// foreground style.
///
/// The view inherits its size from its container rather than from the source
/// image. Missing assets and unknown SF Symbols render as empty images, matching
/// SwiftUI's `Image` behavior.
@preconcurrency @MainActor
public struct MorphingImage: View {
  @Environment(\.accessibilityReduceMotion)
  private var accessibilityReduceMotion

  @Environment(\.morphingImageConfiguration)
  private var configuration

  @State
  private var blurRadius: Double = 0

  @State
  private var transitionState = MorphingTransitionState()

  let image: Image
  let sourceIdentity: MorphingImageSourceIdentity

  /// Creates a morphing image from an image resource.
  ///
  /// - Parameters:
  ///   - name: The name of the image resource to look up.
  ///   - bundle: The bundle to search. When `nil`, SwiftUI searches the main
  ///     bundle.
  public init(_ name: String, bundle: Bundle? = nil) {
    image = Image(name, bundle: bundle)
    sourceIdentity = .asset(name: name, bundlePath: (bundle ?? .main).bundleURL.path)
  }

  /// Creates a morphing image from a system symbol.
  ///
  /// - Parameter systemName: The SF Symbol name.
  public init(systemName: String) {
    image = Image(systemName: systemName)
    sourceIdentity = .system(name: systemName)
  }

  /// Creates a morphing image from an existing SwiftUI image.
  ///
  /// This initializer displays the image but cannot detect subsequent image
  /// changes. Use ``init(image:id:)`` when the image may change.
  ///
  /// - Parameter image: The image to render as a template.
  public init(image: Image) {
    self.image = image
    sourceIdentity = .unidentifiedImage
  }

  /// Creates a morphing image from an existing SwiftUI image and identity.
  ///
  /// Change `id` whenever the image content changes to trigger a morph.
  ///
  /// - Parameters:
  ///   - image: The image to render as a template.
  ///   - id: A stable identity representing the image content.
  public init<ID: Hashable>(image: Image, id: ID) {
    self.image = image
    sourceIdentity = .explicit(AnyHashable(id))
  }

  public var body: some View {
    GeometryReader { reader in
      Canvas(rendersAsynchronously: false) { context, size in
        context.clipToLayer { context in
          context.addFilter(.alphaThreshold(min: configuration.alphaThreshold))
          context.drawLayer { context in
            guard let resolvedImage = context.resolveSymbol(id: 0) else {
              return
            }

            context.draw(
              resolvedImage,
              at: CGPoint(x: size.width / 2, y: size.height / 2)
            )
          }
        }
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .foreground)
      } symbols: {
        symbol(forSize: reader.size).tag(0)
      }
      .task(
        id: MorphingAnimationTaskID(
          sourceIdentity: sourceIdentity,
          reduceMotion: accessibilityReduceMotion,
          configuration: configuration
        )
      ) {
        await animateMorph(forSize: reader.size)
      }
    }
  }

  private func symbol(forSize size: CGSize) -> some View {
    image
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: size.width, height: size.height)
      .id(sourceIdentity)
      .animation(
        configuration.curve.animation(
          duration: configuration.duration,
          phase: .entering
        ),
        value: sourceIdentity
      )
      .blur(radius: blurRadius)
  }

  private func animateMorph(forSize size: CGSize) async {
    let shouldAnimate = transitionState.shouldAnimate(
      to: sourceIdentity,
      duration: configuration.duration,
      reduceMotion: accessibilityReduceMotion
    )

    guard shouldAnimate else {
      blurRadius = 0
      return
    }

    let halfDuration = configuration.duration / 2
    let maximumBlurRadius = configuration.blurRadius(for: size)

    do {
      withAnimation(configuration.curve.animation(duration: halfDuration, phase: .entering)) {
        blurRadius = maximumBlurRadius
      }

      try await MorphingSleep.sleep(seconds: halfDuration)
      try Task.checkCancellation()

      withAnimation(configuration.curve.animation(duration: halfDuration, phase: .leaving)) {
        blurRadius = 0
      }

      try await MorphingSleep.sleep(seconds: halfDuration)
    } catch is CancellationError {
      blurRadius = 0
    } catch {
      blurRadius = 0
    }
  }
}

// MARK: - Configuration

struct MorphingImageConfiguration: Hashable {
  static let `default` = MorphingImageConfiguration(
    duration: 1,
    curve: .easeInOut,
    maximumBlurRadius: 20,
    alphaThreshold: 0.5
  )

  var duration: Double
  var curve: MorphingImageAnimationCurve
  var maximumBlurRadius: Double
  var alphaThreshold: Double

  init(
    duration: Double,
    curve: MorphingImageAnimationCurve,
    maximumBlurRadius: Double,
    alphaThreshold: Double
  ) {
    self.duration = Self.normalizedNonnegative(duration)
    self.curve = curve
    self.maximumBlurRadius = Self.normalizedNonnegative(maximumBlurRadius)
    self.alphaThreshold =
      alphaThreshold.isFinite
      ? min(max(alphaThreshold, 0), 1)
      : Self.defaultAlphaThreshold
  }

  func blurRadius(for size: CGSize) -> Double {
    let width = size.width.isFinite ? max(size.width, 0) : 0
    let height = size.height.isFinite ? max(size.height, 0) : 0
    return min(max(width, height) * 0.05, maximumBlurRadius)
  }

  static func normalizedNonnegative(_ value: Double) -> Double {
    value.isFinite ? max(value, 0) : 0
  }

  @available(iOS 16, macOS 13, tvOS 16, visionOS 1, *)
  static func timeInterval(for duration: Duration) -> Double {
    let components = duration.components
    let seconds = Double(components.seconds)
    let fractionalSeconds = Double(components.attoseconds) / 1_000_000_000_000_000_000
    return normalizedNonnegative(seconds + fractionalSeconds)
  }

  private static let defaultAlphaThreshold = 0.5
}

private struct MorphingImageConfigurationKey: EnvironmentKey {
  static let defaultValue = MorphingImageConfiguration.default
}

extension EnvironmentValues {
  fileprivate var morphingImageConfiguration: MorphingImageConfiguration {
    get { self[MorphingImageConfigurationKey.self] }
    set { self[MorphingImageConfigurationKey.self] = newValue }
  }
}

extension View {
  /// Sets the morphing animation duration in seconds.
  ///
  /// Negative and non-finite values are treated as zero. A zero duration
  /// displays the final image without animation.
  public func morphingImageDuration(_ value: Double) -> some View {
    transformEnvironment(\.morphingImageConfiguration) {
      $0.duration = MorphingImageConfiguration.normalizedNonnegative(value)
    }
  }

  /// Sets the morphing animation duration.
  ///
  /// Negative durations are treated as zero. A zero duration displays the
  /// final image without animation.
  @available(iOS 16, macOS 13, tvOS 16, visionOS 1, *)
  public func morphingImageDuration(_ value: Duration) -> some View {
    morphingImageDuration(MorphingImageConfiguration.timeInterval(for: value))
  }

  /// Sets the timing curve used by the morphing animation.
  public func morphingImageAnimationCurve(_ curve: MorphingImageAnimationCurve) -> some View {
    transformEnvironment(\.morphingImageConfiguration) {
      $0.curve = curve
    }
  }

  /// Sets the maximum blur radius used by the morphing animation.
  ///
  /// Negative and non-finite values are treated as zero.
  public func morphingImageMaximumBlurRadius(_ value: Double) -> some View {
    transformEnvironment(\.morphingImageConfiguration) {
      $0.maximumBlurRadius = MorphingImageConfiguration.normalizedNonnegative(value)
    }
  }

  /// Sets the alpha threshold used to create the morphing silhouette.
  ///
  /// Finite values are clamped to the range `0...1`. Non-finite values use
  /// the default threshold of `0.5`.
  public func morphingImageAlphaThreshold(_ value: Double) -> some View {
    transformEnvironment(\.morphingImageConfiguration) {
      $0.alphaThreshold = value.isFinite ? min(max(value, 0), 1) : 0.5
    }
  }
}

// MARK: - Transition lifecycle

enum MorphingImageSourceIdentity: Hashable {
  case asset(name: String, bundlePath: String)
  case system(name: String)
  case unidentifiedImage
  case explicit(AnyHashable)
}

struct MorphingAnimationTaskID: Hashable {
  let sourceIdentity: MorphingImageSourceIdentity
  let reduceMotion: Bool
  let configuration: MorphingImageConfiguration
}

struct MorphingTransitionState {
  private(set) var previousIdentity: MorphingImageSourceIdentity?

  mutating func shouldAnimate(
    to identity: MorphingImageSourceIdentity,
    duration: Double,
    reduceMotion: Bool
  ) -> Bool {
    defer { previousIdentity = identity }

    guard previousIdentity != nil, previousIdentity != identity else {
      return false
    }

    return duration > 0 && !reduceMotion
  }
}

enum MorphingAnimationPhase {
  case entering
  case leaving
}

enum MorphingSleep {
  static func sleep(seconds: Double) async throws {
    guard seconds > 0 else {
      try Task.checkCancellation()
      return
    }

    if #available(iOS 16, macOS 13, tvOS 16, visionOS 1, *) {
      try await Task.sleep(for: .seconds(seconds))
    } else {
      let state = LegacySleepState()
      try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          state.schedule(seconds: seconds, continuation: continuation)
        }
      } onCancel: {
        state.cancel()
      }
    }
  }
}

private final class LegacySleepState: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<Void, any Error>?
  private var result: Result<Void, any Error>?
  private var workItem: DispatchWorkItem?

  func schedule(
    seconds: Double,
    continuation: CheckedContinuation<Void, any Error>
  ) {
    lock.lock()

    if let result {
      lock.unlock()
      continuation.resume(with: result)
      return
    }

    self.continuation = continuation
    let workItem = DispatchWorkItem { [weak self] in
      self?.finish(with: .success(()))
    }
    self.workItem = workItem
    lock.unlock()

    DispatchQueue.global(qos: .userInitiated).asyncAfter(
      deadline: .now() + seconds,
      execute: workItem
    )
  }

  func cancel() {
    finish(with: .failure(CancellationError()))
  }

  private func finish(with result: Result<Void, any Error>) {
    lock.lock()

    guard self.result == nil else {
      lock.unlock()
      return
    }

    self.result = result
    let continuation = continuation
    self.continuation = nil
    workItem?.cancel()
    workItem = nil
    lock.unlock()

    continuation?.resume(with: result)
  }
}

#Preview {
  TimelineView(.animation(minimumInterval: 2)) { _ in
    MorphingImage(systemName: PreviewSymbols.names.randomElement() ?? "circle.fill")
  }
  .foregroundStyle(.tint)
  .frame(width: 128, height: 128)
}

private enum PreviewSymbols {
  static let names = [
    "circle.fill",
    "heart.fill",
    "star.fill",
    "bell.fill",
    "bookmark.fill",
    "tag.fill",
    "bolt.fill",
    "play.fill",
    "pause.fill",
    "squareshape.fill",
    "key.fill",
    "hexagon.fill",
    "gearshape.fill",
  ]
}
