import Foundation
//import CoreGraphics
import BilliardLib

/*@discardableResult func HalfSpheresRender(
    outputHeight: Int, filename: String,
    _ draw: (CGContext, Sign) -> Void) -> Bool {
  let outputWidth = outputHeight * 2
  guard let context = CGContext(
      data: nil,
      width: outputWidth,
      height: outputHeight,
      bitsPerComponent: 8,
      bytesPerRow: 0, // calculate automatically
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
  else {
    print("Couldn't create image context")
    return false
  }

  // Start with a blank background
  context.beginPath()
  context.move(to: CGPoint(x: 0.0, y: 0.0))
  context.addLine(to: CGPoint(x: Double(outputWidth), y: 0.0))
  context.addLine(to: CGPoint(x: Double(outputWidth), y: Double(outputHeight)))
  context.addLine(to: CGPoint(x: 0.0, y: Double(outputHeight)))
  context.closePath()

  context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  context.fillPath()

  // Set up transforms
  let xCenter = Double(outputWidth) / 2.0
  let yCenter = Double(outputHeight) / 2.0
  // scale so the unit radius is slightly less than the vertical space
  let scale = Double(outputHeight) * 0.475
  context.translateBy(x: CGFloat(xCenter), y: CGFloat(yCenter))
  context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
  //context.scaleBy(x: 0.25, y: 0.25)

  context.setLineWidth(CGFloat(1.0 / scale))
  context.setStrokeColor(
      red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

  let centers: [Sign: Vec2<Double>] = [
    .positive: Vec2(-1.05, 0.0),
    .negative: Vec2(1.05, 0.0)
  ]


  // add a shaded unit circle ( / projected sphere)
  for sign in [Sign.negative, Sign.positive] {
    context.saveGState()
    defer { context.restoreGState() }
    context.translateBy(
        x: CGFloat(centers[sign]!.x), y: CGFloat(centers[sign]!.y))

    context.beginPath()
    context.addArc(
      center: CGPoint(x: 0.0, y: 0.0),
      radius: 1.0,
      startAngle: 0.0,
      endAngle: CGFloat.pi * 2.0,
      clockwise: false
    )
    context.closePath()
    context.setFillColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    context.drawPath(using: .fillStroke)

    draw(context, sign)
  }

  guard let image = context.makeImage()
  else {
    print("Couldn't generate image")
    return false
  }

  let outputURL = URL(fileURLWithPath: filename)

  guard let dest = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
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
