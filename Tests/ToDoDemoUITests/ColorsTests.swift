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

    @Test("Given the device is in dark mode, when the text color on an orange button is resolved, then it is not black")
    func testOnAccentIsNotBlackInDarkMode() {
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        let onAccent = rgb(UIColor(Color.onAccent), in: dark)

        #expect(!isEqual(onAccent, (r: 0, g: 0, b: 0), tolerance: 0.01))
    }

    @Test("Given the orange accent token, when it is resolved in light and in dark mode, then both values are the same orange")
    func testAccentTintIsIdenticalInLightAndDark() {
        let light = rgb(UIColor(Color.accentTint), in: UITraitCollection(userInterfaceStyle: .light))
        let dark = rgb(UIColor(Color.accentTint), in: UITraitCollection(userInterfaceStyle: .dark))
        let orange: RGB = (r: 0.78, g: 0.44, b: 0.32)

        #expect(isEqual(light, dark, tolerance: 0.01))
        #expect(isEqual(light, orange, tolerance: 0.01))
        #expect(isEqual(dark, orange, tolerance: 0.01))
    }

    @Test("Given the device is in light mode, when the card background is resolved, then it is the light gray F2F2F7 and differs from the white page")
    func testCardBackgroundIsLightGrayInLightMode() {
        let light = UITraitCollection(userInterfaceStyle: .light)

        let card = rgb(UIColor(Color.cardBackground), in: light)
        let page = rgb(UIColor.systemBackground, in: light)

        #expect(isEqual(card, (r: 242 / 255, g: 242 / 255, b: 247 / 255), tolerance: 0.01))
        #expect(!isEqual(card, page, tolerance: 0.01))
    }

    @Test("Given the text color on an orange button, when it is resolved in light and in dark mode, then it is white in both")
    func testOnAccentIsWhiteInLightAndDark() {
        let light = rgb(UIColor(Color.onAccent), in: UITraitCollection(userInterfaceStyle: .light))
        let dark = rgb(UIColor(Color.onAccent), in: UITraitCollection(userInterfaceStyle: .dark))

        #expect(isEqual(light, (r: 1, g: 1, b: 1), tolerance: 0.01))
        #expect(isEqual(dark, (r: 1, g: 1, b: 1), tolerance: 0.01))
    }

    @Test("Given the card background token, when the device mode changes between light and dark, then the same token resolves to a different color")
    func testCardBackgroundChangesWhenTraitChanges() {
        let token = UIColor(Color.cardBackground)

        let light = rgb(token, in: UITraitCollection(userInterfaceStyle: .light))
        let dark = rgb(token, in: UITraitCollection(userInterfaceStyle: .dark))

        #expect(!isEqual(light, dark, tolerance: 0.01))
    }

    @Test("Given the device is in dark mode, when the card background is resolved, then it is the elevated dark gray 1C1C1E")
    func testCardBackgroundIsElevatedDarkGrayInDarkMode() {
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        let card = rgb(UIColor(Color.cardBackground), in: dark)

        #expect(isEqual(card, (r: 28 / 255, g: 28 / 255, b: 30 / 255), tolerance: 0.01))
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
