# Crop

A simple crop UI built in SwiftUI.

## Features

- **Interactive Crop Rectangle**: Drag and resize the crop area using corner and edge handles
- **Image Straightening**: Rotate and straighten images with a slider control (±45°)
- **Multiple Images**: Browse and select from multiple test images with a scrollable thumbnail view
- **Live Preview**: View original, cropping, and final output side-by-side
- **Debug Mode**: Visualize crop geometry and transformations

## Components

- `CropRectangleView`: Interactive crop rectangle with draggable handles
- `Viewer`: Image display component with transformation support
- `CropAdjustment`: Model for crop rectangle and straighten adjustments
- `CGRect+Extension`: Geometry utilities for rotation and intersection calculations

## Usage

The app displays three synchronized views:
1. **Left panel**: Original image with thumbnail selector
2. **Center panel**: Interactive crop editor with controls
3. **Right panel**: Final cropped output with debug info

Controls:
- Drag the center circle to move the crop area
- Drag corner/edge handles to resize
- Use the straighten slider to rotate the image
- Toggle the lock icon to constrain to image bounds
- Toggle the bug icon to enable debug visualization

## Technical Challenges

**Constraining Crop Rect to Rotated Image Bounds**
- When an image rotates, its bounds form a diamond shape of the roated image in the original coordinate space
- Used the intersection of a line from the center to the outside corner to find where crop corners intersect the roated image's' edges when they fall outside bounds

**Multiple Coordinate Space Transformations**
- Managed mapping between CoreImage's bottom-left origin and SwiftUI's top-left origin
- Applied aspect-fit scaling and Y-axis flipping to convert between image and view spaces

**Constraining Crop Center During Drag**
- Calculated an inset diamond by finding the bounding box of the rotated crop rectangle
- Constrained the crop center to stay within this inset region so edges never exceed image bounds

---
*Created by Emily Wallace*
