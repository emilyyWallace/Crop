//
//  CropAdjustment.swift
//  Crop
//
//  Created by Emily Wallace on 10/25/25.
//

import CoreImage
import CoreGraphics
import UIKit
import CoreLocation
import Observation

@Observable
class CropAdjustment: Adjustment {

    enum AspectRatio: Int, Codable {
        case original
        case freeform
        case custom
        case standard
    }

    var cropRect: CGRect = .zero
    var straighten: Float = 0.0
    var orientation : CGImagePropertyOrientation? = nil
    var aspectRatioType = AspectRatio.original
    var aspectWidth : Int?
    var aspectHeight : Int?
    var constrain: Bool = true

    static let minWidth = 10.0
    static let minHeight = 10.0

    /// Get the crop rect constrained to the rotated image bounds
    func constrainedCropRect(for imageExtent: CGRect) -> CGRect {
        if constrain {
			let constrint0 = cropRect
			
			let constrain1 = constrint0.constrainCenterToInsetDiamond(bounds: imageExtent, angle: CGFloat(straighten), fromCenter: CGPoint(x: imageExtent.midX, y: imageExtent.midY))
			
			let constrain2 = constrain1.constrained(to: imageExtent, rotatedBy: CGFloat(straighten))
			
            return constrain2
        }
        return cropRect
    }

    func image(for image: CIImage, interactive:Bool = false) -> CIImage {
        // Step 1: Rotate image around its center
        let rotationTransform = transform(imageExtent: image.extent)
        let rotatedImage = image.transformed(by: rotationTransform)

        // Step 2: Get the constrained crop rect
        let constrainedRect = constrainedCropRect(for: image.extent)

        // Step 3: Crop from the rotated image (cropRect is in rotated image space)
        if interactive {
            return rotatedImage
        } else {
            return rotatedImage.cropped(to: constrainedRect)
        }
    }

    /// Get the transform for rotating around image center
    func transform(imageExtent: CGRect) -> CGAffineTransform {
        let radians = CGFloat((self.straighten * Float.pi) / 180.0)
        let imageCenter = CGPoint(x: imageExtent.midX, y: imageExtent.midY)

        // Rotate around image center
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: imageCenter.x, y: imageCenter.y)
        transform = transform.rotated(by: radians)
        transform = transform.translatedBy(x: -imageCenter.x, y: -imageCenter.y)

        return transform
    }
}
