//
//  ContentView.swift
//  Demo
//
//  Created by Jeremy Marchand on 01/10/2022.
//

import ImageMorphing
import SwiftUI

struct ContentView: View {
  private let names = [
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

  @State
  private var index = 0

  private var nextIndex: Int {
    (index + 1) % names.count
  }

  private let gradient = Gradient(colors: [.purple, .red])

  var body: some View {
    ScrollView {
      Box(title: "It is morphing time!", subtitle: "Demo") {
        demo
      }
      Box(title: "How to use?", subtitle: "100% SwiftUI") {
        howTo
      }
    }
    .foregroundStyle(
      .linearGradient(gradient, startPoint: .top, endPoint: .bottom)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private var demo: some View {
    MorphingImage(systemName: names[index])
      .frame(width: 128, height: 128)
      .padding()
      .accessibilityLabel("Current symbol: \(names[index])")

    Button {
      index = nextIndex
    } label: {
      Label {
        Text("Next")
          .fontWeight(.semibold)
      } icon: {
        MorphingImage(systemName: names[nextIndex])
          .frame(width: 16, height: 16)
          .accessibilityHidden(true)
      }
    }
    .foregroundStyle(.white)
    .buttonStyle(.borderedProminent)
    .clipShape(Capsule())
    .tint(.purple)
    .multilineTextAlignment(.center)
    .accessibilityLabel("Show next symbol")
  }

  @ViewBuilder
  private var howTo: some View {
    Text(
      """
      **MorphingImage("MyImage")**
         .frame(width: 64, height: 64)

      **MorphingImage(systemName: "star.fill")**
         .frame(width: 64, height: 64)
      """
    )
    .font(.caption)
  }
}

#Preview {
  ContentView()
}
