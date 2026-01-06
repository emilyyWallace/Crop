//
//  TestImage.swift
//  Crop
//
//  Created by Emily Wallace on 10/25/25.
//

import SwiftUI
import UIKit
import CoreImage

struct TestImages {

	static let allImageNames = ["1", "2", "3", "4", "5", "6", "7", "8"]

    static func image(named:String) -> CIImage {
        guard let uiImage = UIImage(named: named) else {
            fatalError("Missing '\(named)' asset in Assets catalog")
        }
        guard let ciImage = CIImage(image: uiImage) else {
            fatalError("Unable to create CIImage from '\(named)'")
        }
        return ciImage
    }

    
    static func image1() -> CIImage {
        image(named: "1")
    }
    static func image2() -> CIImage {
        image(named: "2")
    }
    static func image3() -> CIImage {
        image(named: "3")
    }
    static func image4() -> CIImage {
        image(named: "4")
    }
    static func image5() -> CIImage {
        image(named: "5")
    }
    static func image6() -> CIImage {
        image(named: "6")
    }
    static func image7() -> CIImage {
        image(named: "7")
    }
    static func image8() -> CIImage {
        image(named: "8")
    }
}
