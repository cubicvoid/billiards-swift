import Foundation

import Clibpng

public class ImageData {
	public let width: Int
	public let height: Int
	// RGBA byte buffer
	public var buffer: [UInt8]

	init(width: Int, height: Int, buffer: [UInt8]) {
		self.width = width
		self.height = height
		self.buffer = buffer
	}

	public init(width: Int, height: Int) {
		self.width = width
		self.height = height
		buffer = Array(repeating: 0, count: width * height * 4)
		buffer.withUnsafeMutableBytes
		{ (bytes: UnsafeMutableRawBufferPointer) in
			let typed = bytes.bindMemory(
				to: UInt32.self)
			for i in typed.indices {
				typed[i] = 0xff000000
			}
		}
	}

	func UInt8FromFloat(_ x: Float) -> UInt8 {
		return UInt8(x * 255.0 + 0.5)
	}

	public func setPixel(row: Int, column: Int, color: RGB) {
		let offset = (row * width + column) * 4 
		buffer[offset] = UInt8FromFloat(color.r)
		buffer[offset+1] = UInt8FromFloat(color.g)
		buffer[offset+2] = UInt8FromFloat(color.b)
	}

	public convenience init?(fromURL url: URL) {
		guard let fp = fopen(url.path, "r")
		else {
			fputs("couldn't open '\(url.relativeString)': \(errno)\n", stderr)
			return nil
		}
		defer { fclose(fp) }

		var pngPtr = png_create_read_struct(
			PNG_LIBPNG_VER_STRING, nil, nil, nil)
		if pngPtr == nil { return nil }

		var infoPtr = png_create_info_struct(pngPtr)
		defer { png_destroy_read_struct(&pngPtr, &infoPtr, nil) }
		if infoPtr == nil {
			return nil
		}

		png_init_io(pngPtr, fp)
		png_read_info(pngPtr, infoPtr)

		let width = Int(png_get_image_width(pngPtr, infoPtr))
		let height = Int(png_get_image_height(pngPtr, infoPtr))
		let colorType = png_get_color_type(pngPtr, infoPtr)
  		let bitDepth  = png_get_bit_depth(pngPtr, infoPtr)
		if colorType != PNG_COLOR_TYPE_RGBA {
			fputs("Png requires images to be 8-bit RGBA", stderr)
			return nil
		}

		// Read any color_type into 8bit depth, RGBA format.
		// See http://www.libpng.org/pub/png/libpng-manual.txt
		// Derived from https://gist.github.com/niw/5963798
		if bitDepth == 16 {
			png_set_strip_16(pngPtr)
		}
		if colorType == PNG_COLOR_TYPE_PALETTE {
			png_set_palette_to_rgb(pngPtr)
		}

		// PNG_COLOR_TYPE_GRAY_ALPHA is always 8 or 16bit depth.
		if colorType == PNG_COLOR_TYPE_GRAY && bitDepth < 8 {
			png_set_expand_gray_1_2_4_to_8(pngPtr)
		}

		if png_get_valid(pngPtr, infoPtr, PNG_INFO_tRNS) != 0 {
			png_set_tRNS_to_alpha(pngPtr)
		}

		// These color_type don't have an alpha channel then fill it with 0xff.
		if colorType == PNG_COLOR_TYPE_RGB ||
			colorType == PNG_COLOR_TYPE_GRAY ||
			colorType == PNG_COLOR_TYPE_PALETTE
		{
			png_set_filler(pngPtr, 0xFF, PNG_FILLER_AFTER)
		}

		if colorType == PNG_COLOR_TYPE_GRAY ||
			colorType == PNG_COLOR_TYPE_GRAY_ALPHA
		{
			png_set_gray_to_rgb(pngPtr)
		}
		
  		png_read_update_info(pngPtr, infoPtr)		
		var buffer = [UInt8](repeating: 0, count: width * height * 4)

		typealias RowPointer = UnsafeMutablePointer<UInt8>
		buffer.withUnsafeMutableBufferPointer { (
			rawBuffer: inout UnsafeMutableBufferPointer<UInt8>
		) -> Void in
			let rowSpan = width * 4
			var rowPointers: [RowPointer?] = []
			for row in 0..<height {
				let rowRange = row * rowSpan..<(row+1)*rowSpan
				let rowBuffer = UnsafeMutableBufferPointer(
					rebasing: rawBuffer[rowRange])
				rowPointers.append(rowBuffer.baseAddress)
			}
			rowPointers.withUnsafeMutableBufferPointer { (
				rowBytes: inout UnsafeMutableBufferPointer<RowPointer?>
			) -> Void in
				png_read_image(pngPtr, rowBytes.baseAddress);
			}
		}

		self.init(width: width, height: height, buffer: buffer)
	}

	public func byteOffsetOfRow(_ row: Int, column: Int) -> Int {
		return (row * width + column) * 4
	}

	@discardableResult public func savePngToUrl(_ url: URL) -> Bool {
		guard let fp = fopen(url.path, "w")
		else {
			fputs("couldn't open '\(url.relativeString)': \(errno)\n", stderr)
			return false
		}
		defer { fclose(fp) }

		var pngPtr =
			png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
		if pngPtr == nil { return false }

		var infoPtr = png_create_info_struct(pngPtr)
		if infoPtr == nil { 
			png_destroy_write_struct(&pngPtr, nil)
			return false
		}
		defer { png_destroy_write_struct(&pngPtr, &infoPtr) }

		png_init_io(pngPtr, fp)
		png_set_IHDR(pngPtr,
			infoPtr,
			png_uint_32(width),
			png_uint_32(height),
			8,	// bit depth
			PNG_COLOR_TYPE_RGBA,
			PNG_INTERLACE_NONE,
			PNG_COMPRESSION_TYPE_DEFAULT,
			PNG_FILTER_TYPE_DEFAULT)
		png_write_info(pngPtr, infoPtr)
		
		buffer.withUnsafeBufferPointer { (
			rawBuffer: UnsafeBufferPointer<UInt8>
		) in
			let rowSpan = width * 4
			for row in 0..<height {
				let rowRange = row*rowSpan..<(row+1)*rowSpan
				let rowBuffer = UnsafeBufferPointer(
					rebasing: rawBuffer[rowRange])
				png_write_row(pngPtr, rowBuffer.baseAddress)
			}
		}
		png_write_end(pngPtr, nil);
		return true
	}

}
