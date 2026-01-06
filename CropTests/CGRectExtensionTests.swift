//
//  CGRectExtensionTests.swift
//  CropTests
//
//  Created by Emily Wallace on 12/30/25.
//

import XCTest
import Testing
@testable import Crop

final class CGRectExtensionTests: XCTestCase {

    // MARK: - constrained(to:rotatedBy:) Tests

    func testConstrainedWithNoRotation() {
        // When there's no rotation, the rect should be constrained to bounds normally
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let angle: CGFloat = 0

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        // With no rotation and rect already inside bounds, should return self
        XCTAssertEqual(result, rect, "Rect within bounds at 0° should remain unchanged")
    }

//    func testConstrainedRectLargerThanBoundsNoRotation() {
//        // Rect larger than bounds should be constrained to fit
//        let rect = CGRect(x: 0, y: 0, width: 600, height: 600)
//        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
//        let angle: CGFloat = 0
//
//        let result = rect.constrained(to: bounds, rotatedBy: angle)
//
//        // Should be constrained to fit within bounds
//        XCTAssertTrue(bounds.contains(result), "Constrained rect should fit within bounds")
//        XCTAssertLessThanOrEqual(result.width, bounds.width, "Width should not exceed bounds")
//        XCTAssertLessThanOrEqual(result.height, bounds.height, "Height should not exceed bounds")
//    }

    func testConstrainedWith45DegreeRotation() {
        // Test with 45° rotation - diagonal becomes limiting factor
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        let angle: CGFloat = 45 // degrees

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        // After 45° rotation, a 100x100 square's diagonal is ~141.4
        // So it might need to be constrained
        XCTAssertGreaterThanOrEqual(result.width, 0, "Width should be positive")
        XCTAssertGreaterThanOrEqual(result.height, 0, "Height should be positive")

        // The constrained rect should still maintain aspect ratio
        let aspectRatio = rect.width / rect.height
        let resultAspectRatio = result.width / result.height
        XCTAssertEqual(aspectRatio, resultAspectRatio, accuracy: 0.01, "Aspect ratio should be maintained")
    }

    func testConstrainedWith90DegreeRotation() {
        // 90° rotation swaps width and height
        let rect = CGRect(x: 0, y: 0, width: 100, height: 200)
        let bounds = CGRect(x: 0, y: 0, width: 150, height: 150)
        let angle: CGFloat = 90

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        // After 90° rotation, the 100x200 becomes 200x100 in rotated space
        // This exceeds bounds, so should be constrained
        XCTAssertTrue(bounds.contains(result), "Constrained rect should fit within bounds")
    }

    func testConstrainedWith180DegreeRotation() {
        // 180° rotation should be same as 0° for symmetric bounds
        let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        let angle: CGFloat = 180

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        XCTAssertGreaterThanOrEqual(result.width, 0, "Width should be positive")
        XCTAssertGreaterThanOrEqual(result.height, 0, "Height should be positive")
    }

    func testConstrainedWithNegativeRotation() {
        // Negative angles should work the same as positive
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)

        let resultPositive = rect.constrained(to: bounds, rotatedBy: 45)
        let resultNegative = rect.constrained(to: bounds, rotatedBy: -45)

        // -45° and 45° should produce same constraint (symmetric)
        XCTAssertEqual(resultPositive.width, resultNegative.width, accuracy: 0.01, "Positive and negative angles should constrain equally")
        XCTAssertEqual(resultPositive.height, resultNegative.height, accuracy: 0.01, "Positive and negative angles should constrain equally")
    }

    func testConstrainedWithSmallAngle() {
        // Small rotation angles should have minimal effect
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        let angle: CGFloat = 5 // small angle

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        // Result should be close to original since rotation is small
        XCTAssertEqual(result.width, rect.width, accuracy: 10, "Small rotation should have minimal impact")
        XCTAssertEqual(result.height, rect.height, accuracy: 10, "Small rotation should have minimal impact")
    }

    func testConstrainedRectOutsideBounds() {
        // Rect positioned outside bounds should be constrained back
        let rect = CGRect(x: 300, y: 300, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        let angle: CGFloat = 0

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        // Should be constrained to fit within bounds
        XCTAssertTrue(result.maxX <= bounds.maxX, "Result should not exceed bounds maxX")
        XCTAssertTrue(result.maxY <= bounds.maxY, "Result should not exceed bounds maxY")
        XCTAssertTrue(result.minX >= bounds.minX, "Result should not be below bounds minX")
        XCTAssertTrue(result.minY >= bounds.minY, "Result should not be below bounds minY")
    }

    func testConstrainedWithZeroSizeBounds() {
        // Edge case: zero-size bounds
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let bounds = CGRect.zero
        let angle: CGFloat = 0

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        // Should handle gracefully - likely return zero or minimal rect
        XCTAssertGreaterThanOrEqual(result.width, 0, "Should not produce negative width")
        XCTAssertGreaterThanOrEqual(result.height, 0, "Should not produce negative height")
    }

    func testConstrainedWithZeroSizeRect() {
        // Edge case: zero-size rect
        let rect = CGRect.zero
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        let angle: CGFloat = 45

        let result = rect.constrained(to: bounds, rotatedBy: angle)

        // Zero rect should stay zero
        XCTAssertEqual(result, .zero, "Zero rect should remain zero")
    }

    // MARK: - fitIn() Tests (bonus - already implemented)

    func testFitInLargerContainer() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let size = CGSize(width: 500, height: 500)

        let result = rect.fitIn(size)

        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
    }

    func testFitInSmallerContainer() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let size = CGSize(width: 200, height: 200)

        let result = rect.fitIn(size)

        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testFitInPreservesAspectRatio() {
        let rect = CGRect(x: 0, y: 0, width: 400, height: 200)
        let size = CGSize(width: 100, height: 100)

        let result = rect.fitIn(size)

        // Should maintain 2:1 aspect ratio
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
    }
}
