//
//  Edit.swift
//  Crop
//
//  Created by Emily Wallace on 10/25/25.
//

import Foundation
import CoreImage
import Observation

@Observable
class Edit {

    var adjustments: [Adjustment]
    var interactive: Bool = false

    init(adjustments: [Adjustment], interactive: Bool = false) {
        self.adjustments = adjustments
        self.interactive = interactive
    }

    func image(for image: CIImage) -> CIImage {

        var adjustedImage = image

        for adjustment in adjustments {
            adjustedImage = adjustment.image(for: adjustedImage, interactive: interactive)
        }

        return adjustedImage
    }
}
