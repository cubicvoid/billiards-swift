import Foundation

import BilliardLib

class PhasePalette {
	let palette: [RGB]
	
	init?(imageURL: URL) {
		guard let palette = PaletteFromImageFile(imageURL)
		else {
			return nil
		}
		self.palette = palette
	}
	
	func colorForCoords(_ z: Vec2<Double>) -> RGB {
		//return palette[0]
		// angle scaled to +-1
		let angle = atan2(z.y, z.x) / Double.pi
		if angle < 0 {
			let positiveAngle = angle + 1.0
			let paletteIndex =
				Int(positiveAngle * (Double(palette.count) - 0.01))
			//paletteIndex = min(paletteIndex, palette.count - 1)
			let rawColor = palette[paletteIndex]
			return RGB(
				r: rawColor.r,// / 2.0,
				g: rawColor.g,// / 2.0,
				b: rawColor.b)// / 2.0)
		}
		let paletteIndex =
			Int(angle * (Double(palette.count - 1) - 0.01))
		return palette[paletteIndex]
	}
}


/*func approxKiteForPath(
	_ path: Path,
	apex: Vec2<Double>
) -> KiteEmbedding {
	
	let baseAngles = BaseValues(
		atan2(apex.y, apex.x) * 2.0,
		atan2(apex.y, 1.0 - apex.x) * 2.0)
	var total = Vec2(0.0, 0.0)

	var curAngle = 0.0
	var orientation = BaseOrientation.to(
	for turn in path {
		let orientation = BaseOrientation.to(turn.singularity)
		
	}
}
*/

// This is not the right way to do this. we just need something that works
// on full nil-rotation cycles while we get things building again. but soon
// we should expand this to work on all paths and verts.
func offsetForPath(
	_ path: TurnPath,
	//constraint: ConstraintSpec,
	apex: Vec2<Double>
) -> Vec2<Double> {

	//let cot = BaseValues(apex.x / apex.y, (1.0 - apex.x) / apex.y)
	var base = BaseValues(Vec2(0.0, 0.0), Vec2(1.0, 0.0))
		//Vec2(-cot[.B0], 0.0),
		//Vec2(cot[.B1], 0.0))
	//let baseLength = cot[.B0] + cot[.B1]
	
	
	let theta = BaseValues(
		atan2(apex.y, apex.x),
		atan2(apex.y, 1.0 - apex.x))

	var curAngle = 0.0
	for turn in path {
		let or = BaseOrientation.from(turn.singularity)
		curAngle += theta[or.from] * 2.0 * Double(turn.degree)
		//let v = base[or.to] - base[or.from]
		// the unit vector in the direction of B0 -> B1
		let delta = Vec2(cos(curAngle), sin(curAngle))
		switch turn.singularity {
		case .B0:
			base[.B1] = base[.B0] + delta
		case .B1:
			base[.B0] = base[.B1] - delta
		}
	}
	return base[.B0]
}

func PlotCycle(_ cycle: TurnCycle) {
	/*guard let constraint: ConstraintSpec = params["constraint"]
	else {
		fputs("pointset plotConstraint: expected constraint\n", stderr)
		return
	}*/
	let path = FileManager.default.currentDirectoryPath
	let paletteURL = URL(fileURLWithPath: path)
		.appendingPathComponent("media")
		.appendingPathComponent("gradient3.png")
	guard let palette = PhasePalette(imageURL: paletteURL)
	else {
		fputs("can't load palette\n", stderr)
		return
	}

	let width = 2000
	let height = 1000
	//let pCenter = Vec2()
	let center = Vec2(0.5, 0.25)
	let scale = 1.0 / 1000.0 //0.00045//1.0 / 2200.0
	let image = ImageData(width: width, height: height)


	let turnPath = cycle.anyPath()
	for py in 0..<height {
		let y = center.y + Double(height/2 - py) * scale
		for px in 0..<width {
			let x = center.x + Double(px - width/2) * scale
			let z = offsetForPath(turnPath, apex: Vec2(x, y))
			let color = palette.colorForCoords(z)
			image.setPixel(row: py, column: px, color: color)
		}
	}

	let imageURL = URL(fileURLWithPath: path)
		.appendingPathComponent("constraint-plot.png")
	image.savePngToUrl(imageURL)
}

