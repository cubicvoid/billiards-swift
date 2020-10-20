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


func offsetForTurnPath(
	_ turnPath: TurnPath,
	//constraint: ConstraintSpec,
	apex: Vec2<Double>
) -> Vec2<Double> {
	
	let baseAngles = BaseValues(
		atan2(apex.y, apex.x) * 2.0,
		atan2(apex.y, 1.0 - apex.x) * 2.0)
	var total = Vec2(0.0, 0.0)

	 var curAngle = 0.0
	 var curOrientation = turnPath.initialOrientation
	 for turn in turnPath.turns {
		 let delta = Vec2(cos(curAngle), sin(curAngle))
		 let summand = (curOrientation == .forward)
			 ? delta
			 : -delta
		total = total + summand
		 
		 curAngle += baseAngles[curOrientation.to] * Double(turn)
		 curOrientation = -curOrientation
	 }
	return total
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


	let turnPath = cycle.asTurnPath()
	for py in 0..<height {
		let y = center.y + Double(height/2 - py) * scale
		for px in 0..<width {
			let x = center.x + Double(px - width/2) * scale
			let z = offsetForTurnPath(turnPath, apex: Vec2(x, y))
			let color = palette.colorForCoords(z)
			image.setPixel(row: py, column: px, color: color)
		}
	}

	let imageURL = URL(fileURLWithPath: path)
		.appendingPathComponent("constraint-plot.png")
	image.savePngToUrl(imageURL)
}

