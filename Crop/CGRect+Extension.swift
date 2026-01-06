//
//  CGRect+Extension.swift
//  Crop
//
//  Created by Emily Wallace on 10/28/25.
//


import CoreGraphics
import Foundation

extension CGRect {
    func fitIn(_ size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0, width > 0, height > 0 else { return .zero }
        let aspectWidth = width / size.width
        let aspectHeight = height / size.height
        let scale = min(aspectWidth, aspectHeight)
        let fittedWidth = size.width * scale
        let fittedHeight = size.height * scale
        let originX = minX + (width - fittedWidth) / 2
        let originY = minY + (height - fittedHeight) / 2
        return CGRect(x: originX, y: originY, width: fittedWidth, height: fittedHeight)
    }

    func description() -> String {
        return String(format: "(%.2f, %.2f) - (%.2f, %.2f)", minX, minY, width, height)
    }

    /// Constrain this rectangle to fit within another rectangle rotated by the given angle
    /// - Parameters:
    ///   - bounds: The bounding rectangle (in original orientation)
    ///   - angle: The rotation angle in degrees
    /// - Returns: A constrained rectangle that fits within the rotated bounds
	
	func constrained(to bounds: CGRect, rotatedBy angle: CGFloat) -> CGRect {
		// return self
		// If no rotation, simple axis-aligned constraint
		let angleInRadians = angle * .pi / 180
		
		if angle == 0 {
			return constrainedAxisAligned(to: bounds)
			
		}
		
		
		let cropCorners:[CGPoint] = [
			CGPoint(x: self.minX, y: self.minY),
			CGPoint(x: self.maxX, y: self.minY),
			CGPoint(x: self.maxX, y: self.maxY),
			CGPoint(x: self.minX, y: self.maxY)
		]
		
		var editedCropCorners:[CGPoint] = [
			CGPoint(x: self.minX, y: self.minY),
			CGPoint(x: self.maxX, y: self.minY),
			CGPoint(x: self.maxX, y: self.maxY),
			CGPoint(x: self.minX, y: self.maxY)
		]
		
		let originalCropCenter = CGPoint(x: self.midX, y: self.midY)
		
		
		/// Get the 4 corners of the bounds rectangle rotated around its center
		
		
		// Original corners of bounds
		let originalCorners:[CGPoint] = [
			CGPoint(x: bounds.minX, y: bounds.minY),
			CGPoint(x: bounds.maxX, y: bounds.minY),
			CGPoint(x: bounds.maxX, y: bounds.maxY),
			CGPoint(x: bounds.minX, y: bounds.maxY)
		]
		let originalCenter = CGPoint(x: bounds.midX, y: bounds.midY)

		// Rotate corners around bounds center to get diamond vertices
		let rotatedCorners:[CGPoint] = originalCorners.map { corner in
			CGRect.rotatePoint(corner, around: originalCenter, by: angleInRadians)
		}

		// Iteratively constrain by adjusting edges (not individual corners)
		var result = self
		
		
		var minX = result.minX
		var maxX = result.maxX
		var minY = result.minY
		var maxY = result.maxY
		
		for index in 0..<4 {
			let corner = cropCorners[index]
			if !CGRect.isPointInRotatedRect(corner, rotatedCorners: rotatedCorners) {
			
				
				if let intersectionPoint = CGRect.findIntersectionWithDiamond(from: originalCropCenter, to: corner, diamondCorners: rotatedCorners){
					
					switch index {
					case 0:
						minX = max(minX, intersectionPoint.x)
						minY = max(minY, intersectionPoint.y)
					case 1:
						maxX = min(maxX, intersectionPoint.x)
						minY = max(minY, intersectionPoint.y)
					case 2:
						maxX = min(maxX, intersectionPoint.x)
						maxY = min(maxY, intersectionPoint.y)
					case 3:
						minX = max(minX, intersectionPoint.x)
						maxY = min(maxY, intersectionPoint.y)
					default:
						continue
					}
				}
				
			}
		}
		
		result = CGRect(x: minX, y:  minY, width: maxX - minX, height: maxY - minY)

		
		
		return result
		
		
		
		
		
		
		
		
		
		
		
//		var iterations = 0
//		let maxIterations = 20

//		while iterations < maxIterations {
//			iterations += 1
//
//		// Get the 4 corners of current rect
//		 
//		// Track edge adjustments
//
//		// Check each corner and adjust corresponding edges
//			var adjusted = false
//			var newMinX: CGFloat = .greatestFiniteMagnitude
//			var newMaxX: CGFloat = -.greatestFiniteMagnitude
//			var newMinY: CGFloat = .greatestFiniteMagnitude
//			var newMaxY: CGFloat = -.greatestFiniteMagnitude
//
//			if !adjusted {
//				// All corners are inside, we're done
//				break
//			}
//
//			// Ensure minimum size
//			if newMaxX - newMinX < 10 || newMaxY - newMinY < 10 {
//				break
//			}
//
//			let newResult = CGRect(x: newMinX, y: newMinY, width: newMaxX - newMinX, height: newMaxY - newMinY)
//
//		// Check if we're making progress
//			if newResult == result {
//				break
//			}
//
//			result = newResult
//		}

		return result
	}

		// MARK: - Helper Functions
	
	func constrainCenterToInsetDiamond(bounds: CGRect, angle: CGFloat, fromCenter: CGPoint) -> CGRect {
		let angleInRadians = angle * .pi / 180
		
		let cropCorners:[CGPoint] = [
			CGPoint(x: self.minX, y: self.minY),
			CGPoint(x: self.maxX, y: self.minY),
			CGPoint(x: self.maxX, y: self.maxY),
			CGPoint(x: self.minX, y: self.maxY)
		]
		var originalCropCenter = CGPoint(x: self.midX, y: self.midY)
		
		let rotatedCropCorners:[CGPoint] = cropCorners.map { corner in
			CGRect.rotatePoint(corner, around: originalCropCenter, by: angleInRadians)
		}
		
		let boundingBox = CGRect.boundingBox(for: rotatedCropCorners)
		let insetWidth = boundingBox.width/2
		let insetHeight = boundingBox.height/2
		
		let insetedImageExtent = bounds.insetBy(dx: insetWidth, dy: insetHeight)
		
		let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
		
		let insetCorners:[CGPoint] = [
			CGPoint(x: insetedImageExtent.minX, y: insetedImageExtent.minY),
			CGPoint(x: insetedImageExtent.maxX, y: insetedImageExtent.minY),
			CGPoint(x: insetedImageExtent.maxX, y: insetedImageExtent.maxY),
			CGPoint(x: insetedImageExtent.minX, y: insetedImageExtent.maxY)
		]
		let insetCenter = CGPoint(x: insetedImageExtent.midX, y: insetedImageExtent.midY)
		
		let rotatedInsetCorners:[CGPoint] = insetCorners.map { corner in
			CGRect.rotatePoint(corner, around: boundsCenter, by: angleInRadians)
		}
		if !CGRect.isPointInRotatedRect(originalCropCenter, rotatedCorners: rotatedInsetCorners) {
			if let interstectionPoint = CGRect.findIntersectionWithDiamond(from: fromCenter, to: originalCropCenter, diamondCorners: rotatedInsetCorners) {
				originalCropCenter = interstectionPoint
			}
		}
		
		let result = CGRect(x: originalCropCenter.x - self.width/2.0, y: originalCropCenter.y - self.height/2.0, width: self.width, height: self.height)
		//print(result)
		return result
	}
	
	static public func boundingBox(for corners: [CGPoint]) -> CGRect {
		var minX:CGFloat = .greatestFiniteMagnitude
		var minY:CGFloat = .greatestFiniteMagnitude
		var maxX:CGFloat = -.greatestFiniteMagnitude
		var maxY:CGFloat = -.greatestFiniteMagnitude
		
		for corner in corners {
			if corner.x < minX {
				minX = corner.x
			}
			if corner.y < minY {
				minY = corner.y
			}
			if corner.x > maxX {
				maxX = corner.x
			}
			if corner.y > maxY {
				maxY = corner.y
			}
		}
		let width = max(1, maxX - minX)
		let height = max(1, maxY - minY)
		
		return CGRect(x: minX, y: minY, width: width, height: height)
	}

	private func constrainedAxisAligned(to bounds: CGRect) -> CGRect {
		var result = self
	
		if result.minX < bounds.minX {
			result.origin.x = bounds.minX
		}
		if result.minY < bounds.minY {
			result.origin.y = bounds.minY
		}
		
		if result.maxX > bounds.maxX {
			result.origin.x = bounds.maxX - result.width
		}
		if result.maxY > bounds.maxY {
			result.origin.y = bounds.maxY - result.height
		}
		
		return result
	}

	
	static public func rotatePoint(_ point: CGPoint, around center: CGPoint, by radians: CGFloat) -> CGPoint {
			let dx = point.x - center.x
			let dy = point.y - center.y
			let cos = cos(radians)
			let sin = sin(radians)
			return CGPoint(
				x: center.x + dx * cos - dy * sin,
				y: center.y + dx * sin + dy * cos
			)
		}

	static public func isPointInRotatedRect(_ point: CGPoint, rotatedCorners: [CGPoint]) -> Bool {
			// Use cross product to check if point is on the same side of = all 4 edges
			for i in 0..<4 {
				let p1 = rotatedCorners[i]
				let p2 = rotatedCorners[(i + 1) % 4]

				// Vector from p1 to p2
				let edgeX = p2.x - p1.x
				let edgeY = p2.y - p1.y

				// Vector from p1 to point
				let toPointX = point.x - p1.x
				let toPointY = point.y - p1.y

				// Cross product (should be positive for all edges if point = is inside)
				let cross = edgeX * toPointY - edgeY * toPointX

				if cross < 0 {
					return false
				}
			}
			return true
		}

		static public func findIntersectionWithDiamond(
			from: CGPoint,
			to: CGPoint,
			diamondCorners: [CGPoint]
		) -> CGPoint? {
			var closestIntersection: CGPoint?
			var closestDistance = CGFloat.infinity

			// Check intersection with each of the 4 edges
			for i in 0..<4 {
				let edgeStart = diamondCorners[i]
				let edgeEnd = diamondCorners[(i + 1) % 4]

				if let intersection = lineSegmentIntersection(
					line1Start: from,
					line1End: to,
					line2Start: edgeStart,
					line2End: edgeEnd
				) {
					let distance = sqrt(pow(intersection.x - from.x, 2) + pow(intersection.y - from.y, 2))
					if distance < closestDistance {
						closestDistance = distance
						closestIntersection = intersection
					}
				}
			}

			return closestIntersection
		}

		static public func lineSegmentIntersection(
			line1Start: CGPoint,
			line1End: CGPoint,
			line2Start: CGPoint,
			line2End: CGPoint
		) -> CGPoint? {
			let x1 = line1Start.x, y1 = line1Start.y
			let x2 = line1End.x, y2 = line1End.y
			let x3 = line2Start.x, y3 = line2Start.y
			let x4 = line2End.x, y4 = line2End.y

			let denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)

			if abs(denom) < 0.0001 {
				return nil // Lines are parallel
			}

			let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
			let u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom

			// Check if intersection is within both line segments
			if t >= 0 && t <= 1 && u >= 0 && u <= 1 {
				return CGPoint(
					x: x1 + t * (x2 - x1),
					y: y1 + t * (y2 - y1)
				)
			}

			return nil
		}
}
