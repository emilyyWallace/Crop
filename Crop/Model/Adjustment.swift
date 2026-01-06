//
//  Adjustment.swift
//  Crop
//
//  Created by Emily Wallace on 10/25/25.
//

import Foundation
import CoreGraphics
import CoreImage

protocol Adjustment {

    func transform(imageExtent: CGRect) -> CGAffineTransform

    func image(for image: CIImage, interactive:Bool) -> CIImage
}
