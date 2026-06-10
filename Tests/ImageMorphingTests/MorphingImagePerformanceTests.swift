import SwiftUI
import XCTest

@testable import ImageMorphing

@MainActor
final class MorphingImagePerformanceTests: XCTestCase {
  func testConstructingGridOfMorphingImagesPerformance() {
    measure {
      for index in 0..<1_000 {
        _ = MorphingImage(image: Image(systemName: "heart.fill"), id: index)
          .morphingImageDuration(0.5)
          .morphingImageMaximumBlurRadius(12)
          .frame(width: 32, height: 32)
      }
    }
  }
}
