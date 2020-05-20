import Foundation
//import CoreGraphics

/*@discardableResult func ContextRenderToURL(
	_ fileURL: URL, width: Int, height: Int, _ draw: (CGContext) -> Void
) -> Bool {

	guard let context = CGContext(
		data: nil,
		width: width,
		height: height,
		bitsPerComponent: 8,
		bytesPerRow: 0, // calculate automatically
		space: CGColorSpaceCreateDeviceRGB(),
		bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
	else {
		print("Couldn't create image context")
		return false
	}
	draw(context)
	// Start with a blank background
	context.beginPath()
	context.move(to: CGPoint(x: 0.0, y: 0.0))
	context.addLine(to: CGPoint(x: Double(width), y: 0.0))
	context.addLine(to: CGPoint(x: Double(width), y: Double(height)))
	context.addLine(to: CGPoint(x: 0.0, y: Double(height)))
	context.closePath()
	
	context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	context.fillPath()
	draw(context)

	guard let image = context.makeImage()
	else {
		print("Couldn't generate image")
		return false
	}

	guard let dest = CGImageDestinationCreateWithURL(
		fileURL as CFURL,
		kUTTypePNG,
		1,
		nil
	) else {
		print("Couldn't create image destination")
		return false
	}
	CGImageDestinationAddImage(dest, image, nil)
	if !CGImageDestinationFinalize(dest) {
		print("Couldn't write image")
		return false
	}
	return true
}*/
