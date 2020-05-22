import Foundation

import Clibpng

public class ImageData {
	public let width: Int
	public let height: Int
	public let data: Data

	public init(width: Int, height: Int) {
		self.width = width
		self.height = height
		data = Data(count: width * height * 4)
	}

	public func SavePngToUrl(_ url: URL) -> Bool {
		let fp = fopen(url.relativeString, "wb")
		guard let pngPtr =
			png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
		else {
			return false
		}
		let infoPtr = png_create_info_struct(pngPtr)
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
		
		let rowSpan = width * 4
		for row in 0..<height {
			let rowPos = row * rowSpan
			let rowData = [UInt8](data[rowPos..<(rowPos + rowSpan)])
			png_write_row(pngPtr, rowData)
		}
		png_write_end(pngPtr, nil);
		fclose(fp)
		return true
	}

}
