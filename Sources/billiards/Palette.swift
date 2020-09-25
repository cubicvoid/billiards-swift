import Foundation

public struct RGB {
	public let r: Float
	public let g: Float
	public let b: Float
}

func FloatFromUInt8(_ z: UInt8) -> Float {
	return Float(z) / 255.0
}

public func PaletteFromImageFile(_ url: URL) -> [RGB]? {
	guard let image = ImageData(fromURL: url)
	else { return nil }
	let rowOffset = image.byteOffsetOfRow(
		image.height / 2, column: 0)
	var result: [RGB] = []
	for i in 0..<image.width {
		let offset = rowOffset + i*4
		result.append(RGB(
			r: FloatFromUInt8(image.buffer[offset]),
			g: FloatFromUInt8(image.buffer[offset+1]),
			b: FloatFromUInt8(image.buffer[offset+2])
		))
	}
	return result
}