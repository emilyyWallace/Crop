//
//  CropOverlayView.swift
//  Crop
//
//  Created by Emily Wallace on 10/27/25.
//

import SwiftUI
import CoreGraphics

struct CropOverlayView: View {
    @Binding var cropAdjustment: CropAdjustment
    let image: CIImage
    let viewTransform: CGAffineTransform
    let lineWidth: CGFloat = 2
    let handleSize: CGFloat = 30
    let edgeHandleThickness: CGFloat = 30
    let cornerHitRadius: CGFloat = 50
    let centerHitRadius: CGFloat = 60
    let edgeCornerPadding: CGFloat = 40
    let debugHandles: Bool

    @State private var straightenStart: CGPoint? = nil
    @State private var straightenEnd: CGPoint? = nil
    @State private var initialViewCropRect: CGRect? = nil
    @State private var previousTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let viewCropRect = viewCropRect(imageCropRect:cropAdjustment.cropRect, viewSize: geo.size)
            let insetRect = viewCropRect.insetBy(dx: lineWidth, dy: lineWidth)

            ZStack {
                // ---- Dim area outside crop ----
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .mask(
                        Rectangle()
                            .fill(Color.white)
                            .overlay(
                                Rectangle()
                                    .path(in: viewCropRect)
                                    .blendMode(.destinationOut)
                            )
                    )

                // ---- Debug: Draw diamond bounds ----
                if debugHandles {
                    let diamondPath = diamondViewPath(viewSize: geo.size)
                    diamondPath
                        .stroke(Color.blue, lineWidth: 2)

                    // Draw center constraint diamond (inset) only when constrain is enabled
                    if cropAdjustment.constrain {
                        let centerDiamondPath = centerConstraintDiamondPath(viewSize: geo.size)
                        centerDiamondPath
                            .stroke(Color.orange, lineWidth: 2)
                    }

                    // Draw intersection points
                    let intersections = getIntersectionPoints(viewSize: geo.size)
                    ForEach(Array(intersections.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .position(point)
                    }
                }

                // ---- Base straighten line (below handles) ----
                if let start = straightenStart, let end = straightenEnd {
                    Path { p in
                        p.move(to: start)
                        p.addLine(to: end)
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4,4]))
                }

                // ---- Crop rectangle and handles ----
                Rectangle()
                    .path(in: viewCropRect)
                    .stroke(Color.red, lineWidth: lineWidth)

                // 🔺 Corner triangles
                ForEach(CropHandle.corners, id: \.self) { handle in
                    let triangleSize = handleSize / 2
                    let triangleOffset = lineWidth + triangleSize / 2
                    let point = handle.innerPosition(for: insetRect, offset: triangleOffset)

                    Triangle()
                        .fill(Color.red)
                        .frame(width: triangleSize, height: triangleSize)
                        .rotationEffect(handle.rotationAngle)
                        .position(point)

                    if debugHandles {
                        Circle()
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                            .frame(width: cornerHitRadius, height: cornerHitRadius)
                            .position(point)
                    }

                    Circle()
                        .fill(Color.clear)
                        .contentShape(Circle())
                        .frame(width: cornerHitRadius, height: cornerHitRadius)
                        .position(point)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if initialViewCropRect == nil {
                                        initialViewCropRect = viewCropRect
                                        previousTranslation = .zero
                                    }

                                    // Calculate delta from previous translation
                                    let delta = CGSize(
                                        width: value.translation.width - previousTranslation.width,
                                        height: value.translation.height - previousTranslation.height
                                    )
                                    previousTranslation = value.translation

                                    // Use current constrained rect, not initial
                                    let currentViewRect = self.viewCropRect(imageCropRect: cropAdjustment.cropRect, viewSize: geo.size)
                                    updateCropDuringDrag(
                                        for: handle,
                                        dragDelta: delta,
                                        startViewRect: currentViewRect,
                                        viewSize: geo.size
                                    )
                                }
                                .onEnded { _ in
                                    initialViewCropRect = nil
                                    previousTranslation = .zero
                                }
                        )
                }

                // 🟦 Edges
                ForEach(CropHandle.edges, id: \.self) { handle in
                    let rect = handle.hitRect(for: viewCropRect, thickness: edgeHandleThickness)
                        .insetBy(dx: handle.isHorizontal ? edgeCornerPadding : 0,
                                 dy: handle.isVertical ? edgeCornerPadding : 0)

                    if debugHandles {
                        Rectangle()
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }

                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if initialViewCropRect == nil {
                                        initialViewCropRect = viewCropRect
                                        previousTranslation = .zero
                                    }

                                    // Calculate delta from previous translation
                                    let delta = CGSize(
                                        width: value.translation.width - previousTranslation.width,
                                        height: value.translation.height - previousTranslation.height
                                    )
                                    previousTranslation = value.translation

                                    // Use current constrained rect, not initial
                                    let currentViewRect = self.viewCropRect(imageCropRect: cropAdjustment.cropRect, viewSize: geo.size)
                                    updateCropDuringDrag(
                                        for: handle,
                                        dragDelta: delta,
                                        startViewRect: currentViewRect,
                                        viewSize: geo.size
                                    )
                                }
                                .onEnded { _ in
                                    initialViewCropRect = nil
                                    previousTranslation = .zero
                                }
                        )
                }

                // 🎯 Center cross
                let center = CGPoint(x: viewCropRect.midX, y: viewCropRect.midY)
                Cross()
                    .stroke(Color.red, lineWidth: 1.5)
                    .frame(width: 12, height: 12)
                    .position(center)

                if debugHandles {
                    Circle()
                        .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        .frame(width: centerHitRadius, height: centerHitRadius)
                        .position(center)
                }

                Circle()
                    .fill(Color.clear)
                    .contentShape(Circle())
                    .frame(width: centerHitRadius, height: centerHitRadius)
                    .position(center)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if initialViewCropRect == nil {
                                    initialViewCropRect = viewCropRect
                                    previousTranslation = .zero
                                }

                                // Calculate delta from previous translation
                                let delta = CGSize(
                                    width: value.translation.width - previousTranslation.width,
                                    height: value.translation.height - previousTranslation.height
                                )
                                previousTranslation = value.translation

                                // Use current constrained rect, not initial
                                let currentViewRect = self.viewCropRect(imageCropRect: cropAdjustment.cropRect, viewSize: geo.size)
                                updateCropDuringDrag(
                                    for: .center,
                                    dragDelta: delta,
                                    startViewRect: currentViewRect,
                                    viewSize: geo.size
                                )
                            }
                            .onEnded { _ in
                                initialViewCropRect = nil
                                previousTranslation = .zero
                            }
                    )
            }
            // ---- Straighten line gesture (under everything else) ----
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        straightenStart = straightenStart ?? value.startLocation
                        straightenEnd = value.location
                    }
                    .onEnded { _ in
                        guard let start = straightenStart, let end = straightenEnd else { return }
                        var dx = end.x - start.x
                        var dy = start.y - end.y // flip Y for image coordinates

                        // Normalize direction so right-to-left gives same result as left-to-right
                        // Always make dx positive by flipping both dx and dy if needed
                        if dx < 0 {
                            dx = -dx
                            dy = -dy
                        }

                        let angleRadians = atan2(dy, dx)
                        let angleDegrees = angleRadians * 180 / .pi

                        // Add to current straighten value instead of replacing it
                        let currentStraighten = cropAdjustment.straighten
                        cropAdjustment.straighten = currentStraighten + Float(-angleDegrees)

                        straightenStart = nil
                        straightenEnd = nil
                    }
            )
        }
        .allowsHitTesting(true)
    }

    // MARK: - Debug Visualization

    /// Get the diamond (rotated image bounds) as a path in view coordinates
    private func diamondViewPath(viewSize: CGSize) -> Path {
        let imageExtent = image.extent
        let radians = CGFloat(cropAdjustment.straighten) * .pi / 180.0
        let imageCenter = CGPoint(x: imageExtent.midX, y: imageExtent.midY)

        // Original corners of the image
        let imageCorners = [
            CGPoint(x: imageExtent.minX, y: imageExtent.minY),
            CGPoint(x: imageExtent.maxX, y: imageExtent.minY),
            CGPoint(x: imageExtent.maxX, y: imageExtent.maxY),
            CGPoint(x: imageExtent.minX, y: imageExtent.maxY)
        ]

        // Rotate corners around image center
        let rotatedCorners = imageCorners.map { corner -> CGPoint in
            let dx = corner.x - imageCenter.x
            let dy = corner.y - imageCenter.y
            let cos = cos(radians)
            let sin = sin(radians)
            return CGPoint(
                x: imageCenter.x + dx * cos - dy * sin,
                y: imageCenter.y + dx * sin + dy * cos
            )
        }

        // Transform to view space
        let viewCorners = rotatedCorners.map { corner -> CGPoint in
            // Apply viewTransform
            let viewPoint = corner.applying(viewTransform)
            // Y-flip
            return CGPoint(x: viewPoint.x, y: viewSize.height - viewPoint.y)
        }

        // Create path
        var path = Path()
        if let first = viewCorners.first {
            path.move(to: first)
            for corner in viewCorners.dropFirst() {
                path.addLine(to: corner)
            }
            path.closeSubpath()
        }

        return path
    }

    /// Get the center constraint diamond (inset) as a path in view coordinates
    private func centerConstraintDiamondPath(viewSize: CGSize) -> Path {
        let imageExtent = image.extent
        let radians = CGFloat(cropAdjustment.straighten) * .pi / 180.0
        let imageCenter = CGPoint(x: imageExtent.midX, y: imageExtent.midY)

        // Original corners of the image
        let imageCorners = [
            CGPoint(x: imageExtent.minX, y: imageExtent.minY),
            CGPoint(x: imageExtent.maxX, y: imageExtent.minY),
            CGPoint(x: imageExtent.maxX, y: imageExtent.maxY),
            CGPoint(x: imageExtent.minX, y: imageExtent.maxY)
        ]

        // Rotate corners around image center
        let rotatedCorners = imageCorners.map { corner -> CGPoint in
            let dx = corner.x - imageCenter.x
            let dy = corner.y - imageCenter.y
            let cos = cos(radians)
            let sin = sin(radians)
            return CGPoint(
                x: imageCenter.x + dx * cos - dy * sin,
                y: imageCenter.y + dx * sin + dy * cos
            )
        }

        // Inset by CONSTRAINED crop dimensions - each edge inset by perpendicular crop dimension
        let constrainedRect = cropAdjustment.constrain
            ? cropAdjustment.constrainedCropRect(for: imageExtent)
            : cropAdjustment.cropRect
        let halfWidth = constrainedRect.width / 2
        let halfHeight = constrainedRect.height / 2

        let insetCorners = insetRectangularPolygon(rotatedCorners, angle: radians, halfWidth: halfWidth, halfHeight: halfHeight)

        // Transform to view space
        let viewCorners = insetCorners.map { corner -> CGPoint in
            // Apply viewTransform
            let viewPoint = corner.applying(viewTransform)
            // Y-flip
            return CGPoint(x: viewPoint.x, y: viewSize.height - viewPoint.y)
        }

        // Create path
        var path = Path()
        if let first = viewCorners.first {
            path.move(to: first)
            for corner in viewCorners.dropFirst() {
                path.addLine(to: corner)
            }
            path.closeSubpath()
        }

        return path
    }

    /// Get intersection points for debugging
    private func getIntersectionPoints(viewSize: CGSize) -> [CGPoint] {
        var points: [CGPoint] = []

        let imageExtent = image.extent
        let radians = CGFloat(cropAdjustment.straighten) * .pi / 180.0
        let imageCenter = CGPoint(x: imageExtent.midX, y: imageExtent.midY)

        // Get rotated diamond corners in image space
        let imageCorners = [
            CGPoint(x: imageExtent.minX, y: imageExtent.minY),
            CGPoint(x: imageExtent.maxX, y: imageExtent.minY),
            CGPoint(x: imageExtent.maxX, y: imageExtent.maxY),
            CGPoint(x: imageExtent.minX, y: imageExtent.maxY)
        ]

        let rotatedDiamondCorners = imageCorners.map { corner -> CGPoint in
            let dx = corner.x - imageCenter.x
            let dy = corner.y - imageCenter.y
            let cos = cos(radians)
            let sin = sin(radians)
            return CGPoint(
                x: imageCenter.x + dx * cos - dy * sin,
                y: imageCenter.y + dx * sin + dy * cos
            )
        }

        // Get crop corners in rotated image space
        let cropCorners = [
            CGPoint(x: cropAdjustment.cropRect.minX, y: cropAdjustment.cropRect.minY),
            CGPoint(x: cropAdjustment.cropRect.maxX, y: cropAdjustment.cropRect.minY),
            CGPoint(x: cropAdjustment.cropRect.maxX, y: cropAdjustment.cropRect.maxY),
            CGPoint(x: cropAdjustment.cropRect.minX, y: cropAdjustment.cropRect.maxY)
        ]

        let cropCenter = CGPoint(x: cropAdjustment.cropRect.midX, y: cropAdjustment.cropRect.midY)

        // For each crop corner, find intersection if it's outside
        for cropCorner in cropCorners {
            // Check if outside diamond (using helper from extension logic)
            let isInside = isPointInPolygon(cropCorner, polygon: rotatedDiamondCorners)

            if !isInside {
                // Find intersection with diamond
                if let intersection = findClosestIntersection(
                    from: cropCorner,
                    to: cropCenter,
                    polygonEdges: rotatedDiamondCorners
                ) {
                    // Convert to view space
                    let viewPoint = intersection.applying(viewTransform)
                    let viewPointFlipped = CGPoint(x: viewPoint.x, y: viewSize.height - viewPoint.y)
                    points.append(viewPointFlipped)
                }
            }
        }

        return points
    }

    private func isPointInPolygon(_ point: CGPoint, polygon: [CGPoint]) -> Bool {
        for i in 0..<polygon.count {
            let p1 = polygon[i]
            let p2 = polygon[(i + 1) % polygon.count]

            let edgeX = p2.x - p1.x
            let edgeY = p2.y - p1.y
            let toPointX = point.x - p1.x
            let toPointY = point.y - p1.y

            let cross = edgeX * toPointY - edgeY * toPointX
            if cross < 0 {
                return false
            }
        }
        return true
    }

    private func findClosestIntersection(from: CGPoint, to: CGPoint, polygonEdges: [CGPoint]) -> CGPoint? {
        var closestIntersection: CGPoint?
        var closestDistance = CGFloat.infinity

        for i in 0..<polygonEdges.count {
            let edgeStart = polygonEdges[i]
            let edgeEnd = polygonEdges[(i + 1) % polygonEdges.count]

            if let intersection = lineIntersection(
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

    private func lineIntersection(
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
            return nil
        }

        let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
        let u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom

        if t >= 0 && t <= 1 && u >= 0 && u <= 1 {
            return CGPoint(
                x: x1 + t * (x2 - x1),
                y: y1 + t * (y2 - y1)
            )
        }

        return nil
    }

    // MARK: - Coordinate conversion


    private func viewCropRect(imageCropRect: CGRect, viewSize:CGSize) -> CGRect {
        // Use constrained crop rect if constrain is enabled
        let constrainedRect = cropAdjustment.constrain
            ? cropAdjustment.constrainedCropRect(for: image.extent)
            : imageCropRect

        // Apply viewTransform to convert to view space (CoreImage Y-up coordinates)
        let viewRectYUp = constrainedRect.applying(viewTransform)

        // Flip Y axis to SwiftUI coordinates (Y-down)
        let result = CGRect(
            x: viewRectYUp.minX,
            y: viewSize.height - viewRectYUp.maxY,
            width: viewRectYUp.width,
            height: viewRectYUp.height
        )
        return result
    }

    // MARK: - Crop updates

    /// Update crop rect during drag (in view space - simple!)
    private func updateCropDuringDrag(
        for handle: CropHandle,
        dragDelta: CGSize,
        startViewRect: CGRect,
        viewSize: CGSize
    ) {
        var rect = startViewRect
        let isCenterDrag = handle == .center

        switch handle {
        // ---- Corners ----
        case .topLeft:
            rect.origin.x += dragDelta.width
            rect.origin.y += dragDelta.height
            rect.size.width -= dragDelta.width
            rect.size.height -= dragDelta.height
        case .topRight:
            rect.size.width += dragDelta.width
            rect.origin.y += dragDelta.height
            rect.size.height -= dragDelta.height
        case .bottomLeft:
            rect.origin.x += dragDelta.width
            rect.size.width -= dragDelta.width
            rect.size.height += dragDelta.height
        case .bottomRight:
            rect.size.width += dragDelta.width
            rect.size.height += dragDelta.height

        // ---- Edges ----
        case .top:
            rect.origin.y += dragDelta.height
            rect.size.height -= dragDelta.height
        case .bottom:
            rect.size.height += dragDelta.height
        case .left:
            rect.origin.x += dragDelta.width
            rect.size.width -= dragDelta.width
        case .right:
            rect.size.width += dragDelta.width

        // ---- Center move ----
        case .center:
            rect.origin.x += dragDelta.width
            rect.origin.y += dragDelta.height
        }

        // Ensure minimum size
        if rect.width < 20 { rect.size.width = 20 }
        if rect.height < 20 { rect.size.height = 20 }

        // Convert to image space and update immediately
        viewRectToImageRect(rect, viewSize: viewSize, centerDrag: isCenterDrag)
    }

    /// Convert view rect to image space and update cropAdjustment
    private func viewRectToImageRect(_ viewRect: CGRect, viewSize: CGSize, centerDrag: Bool = false) {
        // Y-flip from SwiftUI (Y-down) to CoreImage (Y-up)
        let viewRectYUp = CGRect(
            x: viewRect.minX,
            y: viewSize.height - viewRect.maxY,
            width: viewRect.width,
            height: viewRect.height
        )

        // Apply inverse viewTransform to get to rotated image space
        var imageCropRect = viewRectYUp.applying(viewTransform.inverted())

        // Apply constraints if enabled
        if cropAdjustment.constrain {
            if centerDrag {
                // For center drag, constrain the center to an inset diamond
                imageCropRect = constrainCenterToInsetDiamond(imageCropRect, bounds: image.extent, angle: CGFloat(cropAdjustment.straighten))
            } else {
                imageCropRect = imageCropRect.constrained(to: image.extent, rotatedBy: CGFloat(cropAdjustment.straighten))
            }
        }

        cropAdjustment.cropRect = imageCropRect
    }

    /// Constrain center of rect to stay within diamond inset by half rect dimensions
    private func constrainCenterToInsetDiamond(_ rect: CGRect, bounds: CGRect, angle: CGFloat) -> CGRect {
        if angle == 0 {
            // Simple axis-aligned case
            var result = rect
            let halfWidth = rect.width / 2
            let halfHeight = rect.height / 2

            let minX = bounds.minX + halfWidth
            let maxX = bounds.maxX - halfWidth
            let minY = bounds.minY + halfHeight
            let maxY = bounds.maxY - halfHeight

            var centerX = rect.midX
            var centerY = rect.midY

            centerX = max(minX, min(maxX, centerX))
            centerY = max(minY, min(maxY, centerY))

            result.origin.x = centerX - halfWidth
            result.origin.y = centerY - halfHeight

            return result
        }

        // Get rotated diamond corners
        let radians = angle * .pi / 180.0
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)

        let boundCorners = [
            CGPoint(x: bounds.minX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.maxY),
            CGPoint(x: bounds.minX, y: bounds.maxY)
        ]

        let rotatedCorners = boundCorners.map { corner in
            rotatePoint(corner, around: boundsCenter, by: radians)
        }

        // Calculate inset diamond by moving each edge inward by crop dimensions
        let halfWidth = rect.width / 2
        let halfHeight = rect.height / 2

        let insetCorners = insetRectangularPolygon(rotatedCorners, angle: radians, halfWidth: halfWidth, halfHeight: halfHeight)

        // Constrain center point to inset diamond
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let constrainedCenter = constrainPointToPolygon(center, polygon: insetCorners)

        // Return rect with constrained center
        return CGRect(
            x: constrainedCenter.x - halfWidth,
            y: constrainedCenter.y - halfHeight,
            width: rect.width,
            height: rect.height
        )
    }

    private func rotatePoint(_ point: CGPoint, around center: CGPoint, by radians: CGFloat) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let cos = cos(radians)
        let sin = sin(radians)
        return CGPoint(
            x: center.x + dx * cos - dy * sin,
            y: center.y + dx * sin + dy * cos
        )
    }

    /// Inset a rectangular polygon by calculating how far the crop extends perpendicular to each edge
    /// The crop is axis-aligned in image space, but the diamond is rotated
    private func insetRectangularPolygon(_ corners: [CGPoint], angle: CGFloat, halfWidth: CGFloat, halfHeight: CGFloat) -> [CGPoint] {
        guard corners.count == 4 else { return corners }

        var insetCorners: [CGPoint] = []

        for i in 0..<4 {
            let prev = corners[(i + 3) % 4]
            let curr = corners[i]
            let next = corners[(i + 1) % 4]

            // Get edge vectors
            let edge1 = CGPoint(x: curr.x - prev.x, y: curr.y - prev.y)
            let edge2 = CGPoint(x: next.x - curr.x, y: next.y - curr.y)

            // Normalize edge vectors
            let edge1Norm = normalize(edge1)
            let edge2Norm = normalize(edge2)

            // Get perpendicular inward normals
            let normal1 = CGPoint(x: -edge1Norm.y, y: edge1Norm.x)
            let normal2 = CGPoint(x: -edge2Norm.y, y: edge2Norm.x)

            // Calculate inset distance for each edge based on how far the axis-aligned crop
            // extends perpendicular to that edge
            // For an edge with normal direction (nx, ny), an axis-aligned rect with half-dimensions (w, h)
            // extends a perpendicular distance of: |w * nx| + |h * ny|

            let inset1 = abs(halfWidth * normal1.x) + abs(halfHeight * normal1.y)
            let inset2 = abs(halfWidth * normal2.x) + abs(halfHeight * normal2.y)

            // Calculate the corner position by moving along both normals
            let offset1 = CGPoint(x: normal1.x * inset1, y: normal1.y * inset1)
            let offset2 = CGPoint(x: normal2.x * inset2, y: normal2.y * inset2)

            let newCorner = CGPoint(
                x: curr.x + offset1.x + offset2.x,
                y: curr.y + offset1.y + offset2.y
            )

            // Add the offsets directly (for 90-degree corners, these are perpendicular)
            insetCorners.append(newCorner)
        }

        return insetCorners
    }

    private func insetPolygon(_ corners: [CGPoint], by distance: CGFloat) -> [CGPoint] {
        guard corners.count == 4 else { return corners }

        var insetCorners: [CGPoint] = []

        for i in 0..<4 {
            let prev = corners[(i + 3) % 4]
            let curr = corners[i]
            let next = corners[(i + 1) % 4]

            // Get edge vectors
            let edge1 = CGPoint(x: curr.x - prev.x, y: curr.y - prev.y)
            let edge2 = CGPoint(x: next.x - curr.x, y: next.y - curr.y)

            // Get perpendicular inward normals (normalized) - negate for inward
            let normal1 = normalize(CGPoint(x: -edge1.y, y: edge1.x))
            let normal2 = normalize(CGPoint(x: -edge2.y, y: edge2.x))

            // Average the normals to get corner offset direction
            let avgNormal = normalize(CGPoint(
                x: normal1.x + normal2.x,
                y: normal1.y + normal2.y
            ))

            // Calculate offset magnitude (accounting for angle between edges)
            let dotProduct = normal1.x * normal2.x + normal1.y * normal2.y
            let scale = distance / max(0.5, sqrt((1 + dotProduct) / 2))

            // Inset corner
            insetCorners.append(CGPoint(
                x: curr.x + avgNormal.x * scale,
                y: curr.y + avgNormal.y * scale
            ))
        }

        return insetCorners
    }

    private func normalize(_ point: CGPoint) -> CGPoint {
        let length = sqrt(point.x * point.x + point.y * point.y)
        guard length > 0 else { return point }
        return CGPoint(x: point.x / length, y: point.y / length)
    }

    private func constrainPointToPolygon(_ point: CGPoint, polygon: [CGPoint]) -> CGPoint {
        // If already inside, return as-is
        if isPointInPolygon(point, polygon: polygon) {
            return point
        }

        // Find closest point on polygon edges
        var closestPoint = point
        var closestDistance = CGFloat.infinity

        for i in 0..<polygon.count {
            let p1 = polygon[i]
            let p2 = polygon[(i + 1) % polygon.count]

            let closestOnEdge = closestPointOnLineSegment(point: point, lineStart: p1, lineEnd: p2)
            let distance = sqrt(pow(closestOnEdge.x - point.x, 2) + pow(closestOnEdge.y - point.y, 2))

            if distance < closestDistance {
                closestDistance = distance
                closestPoint = closestOnEdge
            }
        }

        return closestPoint
    }

    private func closestPointOnLineSegment(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGPoint {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y

        if dx == 0 && dy == 0 {
            return lineStart
        }

        let t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (dx * dx + dy * dy)
        let tClamped = max(0, min(1, t))

        return CGPoint(
            x: lineStart.x + tClamped * dx,
            y: lineStart.y + tClamped * dy
        )
    }

}

// MARK: - Handles Enum

private enum CropHandle: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
    case top, bottom, left, right
    case center

    static var corners: [CropHandle] { [.topLeft, .topRight, .bottomLeft, .bottomRight] }
    static var edges: [CropHandle] { [.top, .bottom, .left, .right] }

    var isHorizontal: Bool { self == .top || self == .bottom }
    var isVertical: Bool { self == .left || self == .right }

    func position(for rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        case .top: return CGPoint(x: rect.midX, y: rect.minY)
        case .bottom: return CGPoint(x: rect.midX, y: rect.maxY)
        case .left: return CGPoint(x: rect.minX, y: rect.midY)
        case .right: return CGPoint(x: rect.maxX, y: rect.midY)
        case .center: return CGPoint(x: rect.midX, y: rect.midY)
        }
    }

    func innerPosition(for rect: CGRect, offset: CGFloat) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: rect.minX + offset, y: rect.minY + offset)
        case .topRight:
            return CGPoint(x: rect.maxX - offset, y: rect.minY + offset)
        case .bottomLeft:
            return CGPoint(x: rect.minX + offset, y: rect.maxY - offset)
        case .bottomRight:
            return CGPoint(x: rect.maxX - offset, y: rect.maxY - offset)
        default:
            return position(for: rect)
        }
    }

    var rotationAngle: Angle {
        switch self {
        case .topLeft: return .degrees(180)
        case .topRight: return .degrees(270)
        case .bottomLeft: return .degrees(90)
        case .bottomRight: return .degrees(0)
        default: return .zero
        }
    }

    func hitRect(for rect: CGRect, thickness: CGFloat) -> CGRect {
        switch self {
        case .top:
            return CGRect(x: rect.minX, y: rect.minY - thickness / 2,
                          width: rect.width, height: thickness)
        case .bottom:
            return CGRect(x: rect.minX, y: rect.maxY - thickness / 2,
                          width: rect.width, height: thickness)
        case .left:
            return CGRect(x: rect.minX - thickness / 2, y: rect.minY,
                          width: thickness, height: rect.height)
        case .right:
            return CGRect(x: rect.maxX - thickness / 2, y: rect.minY,
                          width: thickness, height: rect.height)
        default:
            return .zero
        }
    }
}

// MARK: - Shapes

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

private struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX, midY = rect.midY
        p.move(to: CGPoint(x: midX, y: rect.minY))
        p.addLine(to: CGPoint(x: midX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX, y: midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: midY))
        return p
    }
}

