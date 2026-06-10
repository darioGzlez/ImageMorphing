import SwiftUI
import XCTest

@testable import ImageMorphing

final class MorphingImageConfigurationTests: XCTestCase {
  func testDurationValidation() {
    XCTAssertEqual(MorphingImageConfiguration.normalizedNonnegative(1.5), 1.5)
    XCTAssertEqual(MorphingImageConfiguration.normalizedNonnegative(0), 0)
    XCTAssertEqual(MorphingImageConfiguration.normalizedNonnegative(-1), 0)
    XCTAssertEqual(MorphingImageConfiguration.normalizedNonnegative(.infinity), 0)
    XCTAssertEqual(MorphingImageConfiguration.normalizedNonnegative(-.infinity), 0)
    XCTAssertEqual(MorphingImageConfiguration.normalizedNonnegative(.nan), 0)
  }

  @available(iOS 16, macOS 13, tvOS 16, visionOS 1, *)
  func testDurationConversion() {
    XCTAssertEqual(
      MorphingImageConfiguration.timeInterval(for: .seconds(1.5)),
      1.5,
      accuracy: 0.000_001
    )
    XCTAssertEqual(MorphingImageConfiguration.timeInterval(for: .seconds(-1)), 0)
  }

  func testAlphaThresholdValidation() {
    XCTAssertEqual(configuration(alphaThreshold: -1).alphaThreshold, 0)
    XCTAssertEqual(configuration(alphaThreshold: 0.75).alphaThreshold, 0.75)
    XCTAssertEqual(configuration(alphaThreshold: 2).alphaThreshold, 1)
    XCTAssertEqual(configuration(alphaThreshold: .infinity).alphaThreshold, 0.5)
    XCTAssertEqual(configuration(alphaThreshold: .nan).alphaThreshold, 0.5)
  }

  func testBlurRadiusForExtremeSizes() {
    let configuration = configuration(maximumBlurRadius: 20)

    XCTAssertEqual(configuration.blurRadius(for: .zero), 0)
    XCTAssertEqual(configuration.blurRadius(for: CGSize(width: 1, height: 1)), 0.05)
    XCTAssertEqual(configuration.blurRadius(for: CGSize(width: 10_000, height: 10_000)), 20)
    XCTAssertEqual(configuration.blurRadius(for: CGSize(width: -10, height: -20)), 0)
    XCTAssertEqual(configuration.blurRadius(for: CGSize(width: CGFloat.infinity, height: 100)), 5)
  }

  private func configuration(
    maximumBlurRadius: Double = 20,
    alphaThreshold: Double = 0.5
  ) -> MorphingImageConfiguration {
    MorphingImageConfiguration(
      duration: 1,
      curve: .easeInOut,
      maximumBlurRadius: maximumBlurRadius,
      alphaThreshold: alphaThreshold
    )
  }
}

final class MorphingTransitionStateTests: XCTestCase {
  func testConsecutiveRapidChangesAreDetected() {
    var state = MorphingTransitionState()

    XCTAssertFalse(
      state.shouldAnimate(to: .system(name: "circle"), duration: 1, reduceMotion: false))
    XCTAssertFalse(
      state.shouldAnimate(to: .system(name: "circle"), duration: 1, reduceMotion: false))
    XCTAssertTrue(
      state.shouldAnimate(to: .system(name: "square"), duration: 1, reduceMotion: false))
    XCTAssertTrue(
      state.shouldAnimate(to: .system(name: "triangle"), duration: 1, reduceMotion: false))
  }

  func testZeroDurationDisplaysFinalImageWithoutAnimation() {
    var state = MorphingTransitionState(previousIdentity: .system(name: "circle"))

    XCTAssertFalse(
      state.shouldAnimate(to: .system(name: "square"), duration: 0, reduceMotion: false))
    XCTAssertEqual(state.previousIdentity, .system(name: "square"))
  }

  func testReduceMotionDisplaysFinalImageWithoutAnimation() {
    var state = MorphingTransitionState(previousIdentity: .system(name: "circle"))

    XCTAssertFalse(
      state.shouldAnimate(to: .system(name: "square"), duration: 1, reduceMotion: true))
    XCTAssertEqual(state.previousIdentity, .system(name: "square"))
  }

  func testSleepRespondsToCancellation() async {
    let task = Task {
      try await MorphingSleep.sleep(seconds: 10)
    }

    task.cancel()

    do {
      try await task.value
      XCTFail("Expected CancellationError")
    } catch is CancellationError {
      // Expected.
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}

@MainActor
final class MorphingImageInitializerTests: XCTestCase {
  func testAssetInitializerUsesBundleInIdentity() {
    let image = MorphingImage("Example", bundle: .main)

    XCTAssertEqual(
      image.sourceIdentity,
      .asset(name: "Example", bundlePath: Bundle.main.bundleURL.path)
    )
  }

  func testSystemSymbolInitializerUsesNameInIdentity() {
    let image = MorphingImage(systemName: "heart.fill")

    XCTAssertEqual(image.sourceIdentity, .system(name: "heart.fill"))
  }

  func testImageInitializerSupportsExplicitIdentity() {
    let unidentified = MorphingImage(image: Image(systemName: "heart.fill"))
    let identified = MorphingImage(image: Image(systemName: "heart.fill"), id: 42)

    XCTAssertEqual(unidentified.sourceIdentity, .unidentifiedImage)
    XCTAssertEqual(identified.sourceIdentity, .explicit(AnyHashable(42)))
  }

  func testPublicConfigurationModifiersCompose() {
    _ = MorphingImage(systemName: "heart.fill")
      .morphingImageDuration(1.5)
      .morphingImageAnimationCurve(.linear)
      .morphingImageMaximumBlurRadius(12)
      .morphingImageAlphaThreshold(0.7)
      .foregroundStyle(.red)

    if #available(iOS 16, macOS 13, tvOS 16, visionOS 1, *) {
      _ = MorphingImage(systemName: "heart.fill")
        .morphingImageDuration(.seconds(1.5))
    }
  }
}

#if os(macOS)
  @available(macOS 13, *)
  @MainActor
  final class MorphingImageRenderingTests: XCTestCase {
    func testForegroundStyleChangesRenderedOutput() throws {
      let red = try renderedData(color: .red)
      let blue = try renderedData(color: .blue)

      XCTAssertFalse(red.isEmpty)
      XCTAssertFalse(blue.isEmpty)
      XCTAssertNotEqual(red, blue)
    }

    private func renderedData(color: Color) throws -> Data {
      let renderer = ImageRenderer(
        content: MorphingImage(systemName: "heart.fill")
          .foregroundStyle(color)
          .frame(width: 128, height: 128)
      )
      renderer.proposedSize = ProposedViewSize(width: 128, height: 128)
      renderer.scale = 1

      return try XCTUnwrap(renderer.cgImage?.dataProvider?.data as Data?)
    }
  }
#endif
