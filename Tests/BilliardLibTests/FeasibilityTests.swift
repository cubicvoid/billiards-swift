import XCTest

import BilliardLib


public func Boundaries<
	k: Field & Comparable & Numeric & Signed
>(
	_ turnPath: TurnPath,
	context: BilliardsContext<k>
) -> (left: [Vec2<k>], right: [Vec2<k>])? {
	if turnPath.count == 0 || turnPath.count % 2 != 0 {
		return nil
	}
	var totals = BaseValues(0, 0)
	for turn in turnPath {
		totals[turn.singularity] += turn.degree
	}
	if totals[.B0] != 0 || totals[.B1] != 0 {
		return nil
	}
	var kite = KiteEmbedding(context: context)

	var leftBoundaries: [Vec2<k>] = []
	var rightBoundaries: [Vec2<k>] = []

	let initialOrientation = BaseOrientation.to(turnPath[0].singularity)
	leftBoundaries.append(kite[initialOrientation.apexForSide(.left)])
	rightBoundaries.append(kite[initialOrientation.apexForSide(.right)])
	for turn in turnPath {
		let turnCoeff =
			context.rotation[turn.singularity].pow(turn.degree, angleBound: .pi)
		if turnCoeff == nil {
			return nil
		}
		// the center (pivot) of the rotation. A positive turn means B0 on
		// the left, B1 on the right, negative is vice versa.
		// we might want to make this construction implicit in the API, with
		// something like an ApexOrientation to complement the BaseOrientation?
		let turnCenter = kite[turn.singularity]
		let turnSign = Sign.of(turn.degree)!
		if turnSign == .positive {
			leftBoundaries.append(turnCenter)
		} else {
			rightBoundaries.append(turnCenter)
		}
		
		// Advance the kite's position and add the exit boundaries
		kite = kite * turn
		let orientation = BaseOrientation.from(turn.singularity)
		leftBoundaries.append(kite[orientation.apexForSide(.left)])
		rightBoundaries.append(kite[orientation.apexForSide(.right)])
	}
	return (left: leftBoundaries, right: rightBoundaries)
}


class FeasibilityTests: XCTestCase {
	func testSimpleCycleFeasibility() {
		let apexCoords = Vec2(x: k(1, over: 2), y: k(7, over: 15))
		let context = BilliardsContext(apex: apexCoords)
		
		let a = TurnPath.g[.B0]
		let b = TurnPath.g[.B1]
		let path = b**(-2) * a**2 * b**2 * a**(-2)
		//let cycle = TurnCycle(repeatingPath: path)
		let result = SimpleCycleFeasibilityForPath(path, context: context)
		
		func trns(_ p: Vec2<k>) -> CGPoint {
			let scale = 75.0
			let offset = Vec2(x: 100.0, y: 500.0)
			return CGPoint(
				x: p.x.asDouble() * scale + offset.x,
				y: p.y.asDouble() * scale + offset.y)
		}
		
		ContextRenderToURL(
			URL(fileURLWithPath: "plot.png"),
			width: 1000, height: 1000)
		{ (ctx: CGContext) in
			
			var kite = KiteEmbedding(context: context)
			
			let p0 = kite[Singularity.B0]
			for turn in path {
				ctx.beginPath()
				ctx.move(to: trns(kite[Singularity.B0]))
				ctx.addLine(to: trns(kite[Singularity.A1]))
				ctx.addLine(to: trns(kite[Singularity.B1]))
				ctx.addLine(to: trns(kite[Singularity.A0]))
				//context.addLine(to: CGPoint(x: Double(width), y: Double(height)))
				//context.addLine(to: CGPoint(x: 0.0, y: Double(height)))
				ctx.closePath()
				ctx.strokePath()
				
				ctx.beginPath()
				let p = trns(kite[turn.singularity])
				/*let centerRect = CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20)
				ctx.addEllipse(in: centerRect)
				ctx.setFillColor(CGColor(red: 0.5, green: 0, blue: 0.5, alpha: 1))
				ctx.fillPath()*/
								
				kite = kite * turn
			}
			let p1 = kite[Singularity.B0]
			
			ctx.beginPath()
			ctx.move(to: trns(kite[Singularity.B0]))
			ctx.addLine(to: trns(kite[Singularity.A1]))
			ctx.addLine(to: trns(kite[Singularity.B1]))
			ctx.addLine(to: trns(kite[Singularity.A0]))
			//context.addLine(to: CGPoint(x: Double(width), y: Double(height)))
			//context.addLine(to: CGPoint(x: 0.0, y: Double(height)))
			ctx.closePath()
			ctx.strokePath()
			
			/*ctx.beginPath()
			ctx.move(to: trns(p0))
			ctx.addLine(to: trns(p1))
			ctx.strokePath()*/
			if let bounds = Boundaries(path, context: context) {
				ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
				for left in bounds.left {
					let p = trns(left)
					let centerRect = CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20)
					ctx.addEllipse(in: centerRect)
					ctx.fillPath()
				}
				ctx.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
				for right in bounds.right {
					let p = trns(right)
					let centerRect = CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20)
					ctx.addEllipse(in: centerRect)
					ctx.fillPath()
				}
			}

		}
		
		XCTAssertEqual(result?.feasible, true)
	}
}
	
