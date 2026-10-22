//
//  ColorsTests.swift
//  ToDoDemoUITests
//

import SwiftUI
import Testing
import UIKit
@testable import ToDoDemoUI

struct ColorsTests {
    @Test("Given the device is in dark mode, when the card background is resolved, then it differs from the black page background so the card stays visible")
    func testCardBackgroundDiffersFromBlackPageInDarkMode() {
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        let card = rgb(UIColor(Color.cardBackground), in: dark)
        let page = rgb(UIColor.systemBackground, in: dark)

        #expect(!isEqual(card, page, tolerance: 0.01))
    }

    private typealias RGB = (r: CGFloat, g: CGFloat, b: CGFloat)

    private func rgb(_ color: UIColor, in traits: UITraitCollection) -> RGB {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    private func isEqual(_ lhs: RGB, _ rhs: RGB, tolerance: CGFloat) -> Bool {
        abs(lhs.r - rhs.r) <= tolerance && abs(lhs.g - rhs.g) <= tolerance && abs(lhs.b - rhs.b) <= tolerance
    }
}
