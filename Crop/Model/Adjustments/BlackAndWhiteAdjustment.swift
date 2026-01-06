//
//  BlackAndWhiteAdjustment.swift
//  Crop
//
//  Created by Emily Wallace on 10/29/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Observation

@Observable
class BlackAndWhiteAdjustment: Adjustment {

    func image(for image: CIImage, interactive: Bool = false) -> CIImage {
        let bwFilter = CIFilter.photoEffectMono()
        bwFilter.inputImage = image

        return bwFilter.outputImage!
    }

    func transform(imageExtent: CGRect) -> CGAffineTransform {
        return .identity
    }

}
