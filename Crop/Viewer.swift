//
//  Viewer.swift
//  Crop
//
//  Created by Emily Wallace on 10/25/25.
//

import SwiftUI
import CoreImage
import SwiftUI
import CoreImage

struct Viewer<Overlay: View, Footer: View>: View {
    let ciImage: CIImage?
    private let context = CIContext()
    let overlay: (CGAffineTransform) -> Overlay
    let footer: () -> Footer

	@State var scale: CGFloat = 1.0
	@State var offset: CGPoint = .zero
	@State var viewSize: CGSize = .zero

    init(ciImage: CIImage?, allowPanZoom: Bool = false, @ViewBuilder overlay: @escaping (CGAffineTransform) -> Overlay = { _ in EmptyView() }, @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }) {
        self.ciImage = ciImage
        self.overlay = overlay
        self.footer = footer
    }

    var body: some View {
            if let ciImage {
                VStack(spacing: 0) {
					ZStack {
						if viewSize.width > 0 && viewSize.height > 0 {
							let t = unflippedTransform()
							let transformedImage = ciImage.transformed(by: t)
							let renderRect = CGRect(origin: .zero, size: viewSize)

							if let cgImage = context.createCGImage(transformedImage, from: renderRect) {
								Image(decorative: cgImage, scale: 1.0, orientation: .up)
									.resizable()
									.aspectRatio(contentMode: .fit)
									.background(Color.gray.opacity(0.1))
									.clipped()
							} else {
								Color.red.opacity(0.3)
							}

							overlay(self.transform())
						}
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.background {
						GeometryReader { geo in
							Color.clear
								.preference(key: ViewerViewSizeKey.self, value: geo.size)
						}
					}
					.onPreferenceChange(ViewerViewSizeKey.self) { size in

						if size == .zero { return }

						viewSize = size
					}

                    footer()
                }
				

            } else {
                Text("Unable to render CIImage")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

    }
	
	public func unflippedTransform() -> CGAffineTransform {
		
		guard let ciImage = ciImage, viewSize.width > 0, viewSize.height > 0 else {
			return .identity
		}

		let extent = ciImage.extent
		let imageSize = extent.size
		guard imageSize.width > 0, imageSize.height > 0 else {
			return .identity
		}

		// Calculate aspect-fit scale (scale to fit image in view)
		let fitScale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)

		// Apply user scale multiplier on top of fit scale
		let combinedScale = fitScale * scale

		// Calculate the center of the image in its original coordinate space
		let imageCenterX = extent.midX
		let imageCenterY = extent.midY

		// Calculate where we want the center to be in the view
		let viewCenterX = viewSize.width / 2 + offset.x
		let viewCenterY = viewSize.height / 2 + offset.y

		// Create transform directly:
		// For a point (x, y): x' = scale * (x - centerX) + viewCenterX
		// Expands to: x' = scale * x + (-scale * centerX + viewCenterX)
		// So: tx = -scale * centerX + viewCenterX, ty = -scale * centerY + viewCenterY
		let tx = -combinedScale * imageCenterX + viewCenterX
		let ty = -combinedScale * imageCenterY + viewCenterY

		let transform = CGAffineTransform(
			a: combinedScale, b: 0,
			c: 0, d: combinedScale,
			tx: tx, ty: ty
		)
		
		return transform
	}
	
	private func transform() -> CGAffineTransform {
		let yFlipTransform = CGAffineTransform(
			a: 1,  b: 0,
			c: 0,  d: -1,
			tx: 0, ty: viewSize.height
		)

		return self.unflippedTransform().concatenating(yFlipTransform)
	}
	
}

internal struct ViewerViewSizeKey: PreferenceKey {
	static var defaultValue: CGSize = .zero
	
	static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
		let next = nextValue()
		if next != .zero {
			value = next
		}
	}
}
