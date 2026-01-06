//
//  CropRectangleView.swift
//  Crop
//
//  Created by Emily Wallace on 12/29/25.
//

import SwiftUI

struct CropRectangleView: View {
	let image: CIImage
	let viewTransform: CGAffineTransform
	@Binding var cropAdjustment: CropAdjustment
	@Binding var viewRect: CGRect
	@State var dragStartRect: CGRect? = nil
	@Binding var debug:Bool
	
	@State private var selectedColor: Color = .blue
	
	let MIN_SIZE: CGFloat = 65
	
	enum CropHandle {
		case topLeft
		case topRight
		case bottomLeft
		case bottomRight
		case leftEdge
		case topEdge
		case rightEdge
		case bottomEdge
	}
	
    var body: some View {
		let imageViewRect = image.extent.applying(viewTransform)
		ZStack {
			// Border
			
			Rectangle()
				.path(in: viewRect)
				.stroke(.white, lineWidth: 3)
			
			ZStack {
				// Big invisible hit area (nice on touch)
				Rectangle()
					.fill(debug ? Color.green.opacity(0.5) : Color.clear)
					.frame(width: viewRect.width, height: viewRect.height)
					.contentShape(Rectangle())
					

				// Visible knob
				Circle()
					.fill(Color.white)
					.frame(width: 25, height: 25)
					.shadow(radius: 2)
			}
			.position(x: (viewRect.minX + viewRect.maxX)/2, y: (viewRect.minY + viewRect.maxY)/2)
			.onAppear {
				viewRect = cropAdjustment.constrainedCropRect(for: image.extent).applying(viewTransform)
			}
			.onChange(of: cropAdjustment.cropRect) { value, _ in
				viewRect = cropAdjustment.constrainedCropRect(for: image.extent).applying(viewTransform)
			}
			.onChange(of: viewTransform) { value, _ in
				viewRect = cropAdjustment.constrainedCropRect(for: image.extent).applying(viewTransform)
			}
			.gesture(
				DragGesture() //Drag gesture for Center
					.onChanged { value in
						var prevCenter:CGPoint = .zero
						
						if dragStartRect == nil {
							dragStartRect = viewRect
							prevCenter = CGPoint(x: cropAdjustment.cropRect.midX, y: cropAdjustment.cropRect.midY)
						}
						
						var dragViewRect = viewRect
						
						let start = dragStartRect!
						dragViewRect = start.offsetBy(
							dx: value.translation.width,
							dy: value.translation.height
						)
						
						cropAdjustment.cropRect = dragViewRect.applying(viewTransform.inverted())
						 
						
//						if !cropAdjustment.constrain {
//							let start = dragStartRect!
//							dragViewRect = start.offsetBy(
//								dx: value.translation.width,
//								dy: value.translation.height
//							)
//							
//							cropAdjustment.cropRect = dragViewRect.applying(viewTransform.inverted())
//						} else {
//							let start = dragStartRect!
//							dragViewRect = start.offsetBy(
//								dx: value.translation.width,
//								dy: value.translation.height
//							)
//							let angleInRadians:CGFloat = CGFloat(cropAdjustment.straighten * .pi/180.0)
//							let newCropRect = dragViewRect.applying(viewTransform.inverted())
//							
//							cropAdjustment.cropRect = newCropRect.constrainCenterToInsetDiamond(bounds: image.extent, angle: angleInRadians, fromCenter: prevCenter)
//							
//							prevCenter = CGPoint(x: cropAdjustment.cropRect.midX, y: cropAdjustment.cropRect.midY)
//						}

					}
					.onEnded { _ in
						dragStartRect = nil
					}
			)
			
			
			
			/// Corners
			Handle(
				center: CGPoint(x: viewRect.minX, y: viewRect.minY),
				debug: $debug
			)
			.highPriorityGesture(
				cornerGesture(.topLeft)
			)

			Handle(
				center: CGPoint(x: viewRect.maxX, y: viewRect.minY),
				debug: $debug
			)
			.highPriorityGesture(
				cornerGesture(.topRight)
			)

			Handle(
				center: CGPoint(x: viewRect.minX, y: viewRect.maxY),
				debug: $debug
			)
			.highPriorityGesture(
				cornerGesture(.bottomLeft)
			)

			Handle(
				center: CGPoint(x: viewRect.maxX, y: viewRect.maxY),
				debug: $debug
			)
			.highPriorityGesture(
				cornerGesture(.bottomRight)
			)
			
			/// Edges
			
			EdgeHandle(
				width: 30,
				height: viewRect.height - 50,
				center: CGPoint(x: viewRect.minX, y: viewRect.midY),
				debug: $debug
			)
			.gesture(
				cornerGesture(.leftEdge)
			)
			
			EdgeHandle(
				width: viewRect.width - 50,
				height: 30,
				center: CGPoint(x: viewRect.midX, y: viewRect.minY),
				debug: $debug
			)
			.gesture(
				cornerGesture(.topEdge)
			)
			
			EdgeHandle(
				width: 30,
				height: viewRect.height - 50,
				center: CGPoint(x: viewRect.maxX, y: viewRect.midY),
				debug: $debug
			)
			.gesture(
				cornerGesture(.rightEdge)
			)
			
			EdgeHandle(
				width: viewRect.width - 50,
				height: 30,
				center: CGPoint(x: viewRect.midX, y: viewRect.maxY),
				debug: $debug
			)
			.gesture(
				cornerGesture(.bottomEdge)
			)
			
			if debug {
				let angleInRadians:CGFloat = CGFloat(cropAdjustment.straighten * .pi/180.0)
				
				let bounds = image.extent
				let originalCorners:[CGPoint] = [
					CGPoint(x: bounds.minX, y: bounds.minY),
					CGPoint(x: bounds.maxX, y: bounds.minY),
					CGPoint(x: bounds.maxX, y: bounds.maxY),
					CGPoint(x: bounds.minX, y: bounds.maxY)
				]
				let originalCenter = CGPoint(x: bounds.midX, y: bounds.midY)
				
				
				ForEach(originalCorners, id: \.self) { c in
					let rc = CGRect.rotatePoint(c, around: originalCenter, by: angleInRadians)
					let vrc = rc.applying(viewTransform)
					
					ZStack {
						Circle()
							.fill(Color.red)
							.frame(width: 10, height: 10)
							.shadow(radius: 2)
					}
					.position(x: vrc.x, y: vrc.y)
					
				}
				let rotatedCorners:[CGPoint] = originalCorners.map { corner in
					CGRect.rotatePoint(corner, around: originalCenter, by: angleInRadians)
				}
				
				let cropRect = cropAdjustment.cropRect
				
				let cropCorners:[CGPoint] = [
					CGPoint(x: cropRect.minX, y: cropRect.minY),
					CGPoint(x: cropRect.minX, y: cropRect.maxY),
					CGPoint(x: cropRect.maxX, y: cropRect.minY),
					CGPoint(x: cropRect.maxX, y: cropRect.maxY)
				]
				
				let originalCropCenter = CGPoint(x: cropRect.midX, y: cropRect.midY)
				
				ForEach(cropCorners, id: \.self) { corner in
					if !CGRect.isPointInRotatedRect(corner, rotatedCorners: rotatedCorners) {
						
						let pt = corner.applying(viewTransform)
						ZStack {
							Circle()
								.fill(Color.green)
								.frame(width: 10, height: 10)
								.shadow(radius: 2)
						}
						.position(x: pt.x, y: pt.y)
						
						
						if let intesectionPoint = CGRect.findIntersectionWithDiamond(from: originalCropCenter, to: corner, diamondCorners: rotatedCorners){
							let vip = intesectionPoint.applying(viewTransform)
							ZStack {
								Circle()
									.fill(Color.orange)
									.frame(width: 10, height: 10)
									.shadow(radius: 2)
							}
							.position(x: vip.x, y: vip.y)
						}
					}
				}

				
				
				let rotatedCropCorners:[CGPoint] = cropCorners.map { corner in
					CGRect.rotatePoint(corner, around: originalCropCenter, by: angleInRadians)
				}
				
				let boundingBox = CGRect.boundingBox(for: rotatedCropCorners)
				let insetWidth = boundingBox.width/2
				let insetHeight = boundingBox.height/2
				
				
				
				
				let insetedImageExtent = image.extent.insetBy(dx: insetWidth, dy: insetHeight)
				
				let insetCorners:[CGPoint] = [
					CGPoint(x: insetedImageExtent.minX, y: insetedImageExtent.minY),
					CGPoint(x: insetedImageExtent.maxX, y: insetedImageExtent.minY),
					CGPoint(x: insetedImageExtent.maxX, y: insetedImageExtent.maxY),
					CGPoint(x: insetedImageExtent.minX, y: insetedImageExtent.maxY)
				]
				let insetCenter = CGPoint(x: insetedImageExtent.midX, y: insetedImageExtent.midY)
				
				let rotatedInsetCorners:[CGPoint] = insetCorners.map { corner in
					CGRect.rotatePoint(corner, around: originalCenter, by: angleInRadians).applying(viewTransform)
				}
				
				let path = path(for : rotatedInsetCorners)
				
				path.stroke(Color.orange, lineWidth: 2)
				
			}
			
			
		}
    }
	
	
	private func path(for corners: [CGPoint]) -> Path {
		var path = Path()
		
		for corner in corners {
			
			if path.currentPoint == nil {
				path.move(to: corner)
			} else {
				path.addLine(to: corner)
			}
		}
		
		path.closeSubpath()
		
		
		return path
	}
	
	
	private func cornerGesture(_ cropHandle: CropHandle) -> some Gesture {
		 return DragGesture()
			.onChanged { value in
				if dragStartRect == nil {
					dragStartRect = viewRect
				}

				let dragViewRect = viewRect

				let start = dragStartRect!
				var changedRect = CGRect()
				
				var newX:CGFloat = 0
				var newY:CGFloat = 0
				var newWidth:CGFloat = 0
				var newHeight:CGFloat = 0
				var dx:CGFloat = 0
				var dy:CGFloat = 0
				
				switch cropHandle {
				case .topLeft:
					
					dx = value.translation.width
					dy = value.translation.height
					
					if start.width-dx < MIN_SIZE {
						dx = start.width-MIN_SIZE
					}

					if start.height-dy < MIN_SIZE {
						dy = start.height-MIN_SIZE
					}
					
					newX = start.minX + dx
					newY = start.minY +  dy
					newWidth = start.width - dx
					newHeight = start.height - dy

					
					//work
					
					
				case .topRight:
					dx = value.translation.width
					dy = value.translation.height

					if start.width+dx < MIN_SIZE {
						dx = MIN_SIZE - start.width  // FIX: was start.width-MIN_SIZE
					}

					if start.height-dy < MIN_SIZE {
						dy = start.height-MIN_SIZE
					}

					newX = start.minX
					newY = start.minY + dy
					newWidth = start.width + dx
					newHeight = start.height - dy
					
				case .bottomLeft:

					dx = value.translation.width
					dy = value.translation.height

					if start.width-dx < MIN_SIZE {
						dx = start.width-MIN_SIZE
					}

					if start.height+dy < MIN_SIZE {
						dy = MIN_SIZE - start.height  // FIX: was start.height-MIN_SIZE
					}
					
					newX = start.minX + dx
					newY = start.minY
					newWidth = start.width - dx
					newHeight = start.height + dy

				case .bottomRight:
					dx = value.translation.width
					dy = value.translation.height

					if start.width+dx < MIN_SIZE {
						dx = MIN_SIZE - start.width  // FIX: was start.width-MIN_SIZE
					}

					if start.height+dy < MIN_SIZE {
						dy = MIN_SIZE - start.height  // FIX: was start.height-MIN_SIZE
					}
					
					newX = start.minX
					newY = start.minY
					newWidth = start.width + dx
					newHeight = start.height + dy
					
				case .leftEdge:
					
					dx = value.translation.width
					
					if start.width-dx < MIN_SIZE {
						dx = start.width-MIN_SIZE
					}

					newX = start.minX +  dx
					newY = start.minY
					newWidth = start.width - dx
					newHeight = start.height
				case .topEdge:
					
					dy = value.translation.height
					
					if start.height-dy < MIN_SIZE {
						dy = start.height-MIN_SIZE
					}
					
					newX = start.minX
					newY = start.minY +  dy
					newWidth = start.width
					newHeight = start.height - dy
				
				case .rightEdge:
					dx = value.translation.width

					if start.width+dx < MIN_SIZE {
						dx = MIN_SIZE - start.width  // FIX: was start.width-MIN_SIZE
					}
					
					newX = start.minX
					newY = start.minY
					newWidth = start.width + dx
					newHeight = start.height
					
				case .bottomEdge:
					dy = value.translation.height

					if start.height+dy < MIN_SIZE {
						dy = MIN_SIZE - start.height
					}

					newX = start.minX
					newY = start.minY
					newWidth = start.width
					newHeight = start.height + dy
				}
				
//				if newWidth < MIN_SIZE {
//					//newX = start.minX
//					newWidth = MIN_SIZE
//				}
//				
//				if newHeight < MIN_SIZE {
//					//newY = start.minY
//					newHeight = MIN_SIZE
//				}
				
				changedRect = CGRect(
					x: newX,
					y: newY,
					width: newWidth,
					height: newHeight
				)

				cropAdjustment.cropRect = changedRect.applying(viewTransform.inverted())

			}
			.onEnded { _ in
				dragStartRect = nil
			}
	}
}

struct Handle: View {
	let center: CGPoint
	@Binding var debug:Bool

	var body: some View {
		ZStack {
			Circle()
				.fill(debug ? Color.blue.opacity(0.5) : Color.clear)
				.frame(width: 50, height: 50)
				.contentShape(Circle())

			Circle()
				.fill(Color.white)
				.frame(width: 10, height: 10)
				.shadow(radius: 2)
		}
		.position(x: center.x, y: center.y)
	}
}

struct EdgeHandle: View {
	let width: CGFloat
	let height: CGFloat
	let center: CGPoint
	@Binding var debug:Bool

	var body: some View {
		ZStack {
			Capsule()
				.fill(debug ? Color.red.opacity(0.5) : Color.clear)
				.frame(width: width, height: height)
				.contentShape(Capsule())

			Circle()
				.fill(Color.white)
				.frame(width: 10, height: 10)
				.shadow(radius: 2)
		}
		.position(x: center.x, y: center.y)
	}
}

//#Preview {
//    CropRectangleView()
//}
