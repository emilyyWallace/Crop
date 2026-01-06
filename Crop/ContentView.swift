//
//  ContentView.swift
//  Crop
//
//  Created by Emily Wallace on 10/25/25.
//

import SwiftUI

struct ContentView: View {

    @State var image:CIImage = TestImages.image1()
    @State var selectedImageName: String = "1"
    @State var cropAdjustment:CropAdjustment = CropAdjustment()
    @State var interactiveEdit:Edit
    @State var finalEdit:Edit
    @State var straighten:Float = 0.0
    @State var debug:Bool = false
	@State var viewRect: CGRect = .zero
	@State var centeredName: String? = nil
	@State var zoomLevel: CGFloat = .zero


    init() {
        let cropAdjustment = CropAdjustment()
        _cropAdjustment = State(initialValue: cropAdjustment)
        _interactiveEdit = State(initialValue: Edit(adjustments: [cropAdjustment], interactive: true))
        _finalEdit = State(initialValue: Edit(adjustments: [cropAdjustment, BlackAndWhiteAdjustment()], interactive: false))
    }

    
    var body: some View {
        
        
        GeometryReader { geometry in

			let footerHeight = 150.0
            let buttonSize = 44.0
            let buttonMargin = 10.0
            let buttonForeground:Color = .white
            let buttonBackground:Color = .gray
        
    
            VStack {
                HStack(spacing: 10.0) {
                    VStack {
						Slider(value: $zoomLevel, in: 0...400)
						.onChange(of: zoomLevel) { oldValue, newValue in
								  //cropAdjustment.straighten = newValue
							  }
						.padding()
						
                        Viewer(ciImage: image, allowPanZoom: true) { viewTransform in
							EmptyView()
                        } footer: {
                            VStack {
                                Text("Image extent: \(image.extent.debugDescription)")

                                ScrollView(.horizontal, showsIndicators: true) {
                                    HStack(spacing: 8) {
                                        ForEach(TestImages.allImageNames, id: \.self) { name in
                                            Button(action: {
												withAnimation(.snappy) {
													centeredName = name   // this scrolls it to center
												}
                                            }) {
                                                if let uiImage = UIImage(named: name) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(selectedImageName == name ? Color.blue : Color.clear, lineWidth: 3)
                                                        )
                                                        .padding(2)
                                                }
                                            }
                                            .buttonStyle(.plain)
											.id(name)
                                        }
                                    }
									.scrollTargetLayout()
									.padding(.horizontal)
                                }
								.contentMargins(.horizontal, 270)
								.scrollIndicators(.hidden)
								.scrollTargetLayout()
								.scrollPosition(id: $centeredName, anchor: .center)
								.onChange(of: centeredName) { _, newValue in
										guard let name = newValue else { return }
										selectedImageName = name
										image = TestImages.image(named: name)
										reset()
									}
                            }
                            .frame(width:.infinity, height: footerHeight)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        let editedImage = interactiveEdit.image(for: image)
                        Viewer(ciImage: editedImage) { viewTransform in
                            // Put your edit overlay view in here
							CropRectangleView(image: image, viewTransform: viewTransform, cropAdjustment: $cropAdjustment, viewRect: $viewRect, debug: $debug)
				
                        } footer: {
							// Put your straighten slider in here
                            VStack(spacing: 0.0) {
                                HStack {
									Button {
										debug.toggle()
									} label: {
										Image(systemName: "ladybug")
											.font(.system(size: 18, weight: .semibold))
											.foregroundStyle(debug ? .white : .secondary)
											.frame(width: 44, height: 44)
											.background(
												Circle()
													.fill(debug ? Color.red : Color(.systemGray5))
											)
									}
									.buttonStyle(.plain)
									
									Button {
										cropAdjustment.constrain.toggle()
										print(cropAdjustment.constrain)
									} label: {
										Image(systemName: "lock")
											.font(.system(size: 18, weight: .semibold))
											.foregroundStyle(cropAdjustment.constrain ? .white : .secondary)
											.frame(width: 44, height: 44)
											.background(
												Circle()
													.fill(cropAdjustment.constrain ? Color.blue : Color(.systemGray5))
											)
									}
									.buttonStyle(.plain)
                                }
                                .padding()
								
								Slider(value: $straighten, in: -45.0...45.0)
								.onChange(of: straighten) { oldValue, newValue in
										  cropAdjustment.straighten = newValue
									  }
                            }
                            .frame(width:.infinity, height: footerHeight)
                        }
						
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        let finalImage = finalEdit.image(for: image)
                        Viewer(ciImage: finalImage) { _ in
                            EmptyView()
                        } footer: {
                            VStack {
                                Text("Crop: \(cropAdjustment.cropRect.description())")
                                Text("Straighten: \(String(format: "%.2f", cropAdjustment.straighten))")
                            }
                            .frame(width:.infinity, height: footerHeight)
                       }
                    }
                    .frame(maxWidth: .infinity)
                }
                .onAppear {
					reset()
					//viewRect = cropAdjustment.cropRect.applying(viewTransform)
                    
                }

            }
        }
    }
    
	private func reset() {
		 let imageSize = image.extent.size

		 // Crop to 1/4 area (1/2 width × 1/2 height), centered
		 let cropWidth = imageSize.width * 0.25
		 let cropHeight = imageSize.height * 0.25
		 let cropX = (imageSize.width - cropWidth) / 4   // centers horizontally
		 let cropY = (imageSize.height - cropHeight) / 4  // centers vertically

		 cropAdjustment.cropRect = CGRect(
			 x: cropX,
			 y: cropY,
			 width: cropWidth,
			 height: cropHeight
		 )
		//let imageRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
		
//		let imageExtent = image.extent
//		let radians = CGFloat((self.straighten * Float.pi) / 180.0)
//		let imageCenter = CGPoint(x: imageExtent.midX, y: imageExtent.midY)
//
//		// Rotate around image center
//		var transform = CGAffineTransform.identity
//		transform = transform.translatedBy(x: imageCenter.x, y: imageCenter.y)
//		transform = transform.rotated(by: radians)
//		transform = transform.translatedBy(x: -imageCenter.x, y: -imageCenter.y)

		//viewRect = imageRect.applying(transform)
			
		
		straighten = 0.0
		cropAdjustment.straighten = 0.0
		
	 }
}



#Preview {
    ContentView()
}

