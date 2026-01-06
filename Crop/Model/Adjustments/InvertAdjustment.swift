//
//  InvertAdjustment.swift
//  Crop
//
//  Created by Emily Wallace on 10/25/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Observation

@Observable
class InvertAdjustment: Adjustment {

    func image(for image: CIImage, interactive:Bool = false) -> CIImage {
        let invertFilter = CIFilter.colorInvert()
        invertFilter.inputImage = image

        return invertFilter.outputImage!
    }

    func transform(imageExtent: CGRect) -> CGAffineTransform {
        return .identity
    }
    
}
