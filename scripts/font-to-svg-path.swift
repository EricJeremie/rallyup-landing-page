import AppKit
import CoreText
import Foundation

struct OutlinedRun: Encodable {
  let width: Double
  let groups: [String: String]
}

func number(_ value: CGFloat) -> String {
  let rounded = (value * 1000).rounded() / 1000
  return String(format: "%.3f", Double(rounded))
}

func svgPath(_ path: CGPath) -> String {
  var commands: [String] = []
  path.applyWithBlock { elementPointer in
    let element = elementPointer.pointee
    let points = element.points
    switch element.type {
    case .moveToPoint:
      commands.append("M\(number(points[0].x)) \(number(points[0].y))")
    case .addLineToPoint:
      commands.append("L\(number(points[0].x)) \(number(points[0].y))")
    case .addQuadCurveToPoint:
      commands.append("Q\(number(points[0].x)) \(number(points[0].y)) \(number(points[1].x)) \(number(points[1].y))")
    case .addCurveToPoint:
      commands.append("C\(number(points[0].x)) \(number(points[0].y)) \(number(points[1].x)) \(number(points[1].y)) \(number(points[2].x)) \(number(points[2].y))")
    case .closeSubpath:
      commands.append("Z")
    @unknown default:
      break
    }
  }
  return commands.joined(separator: " ")
}

func outline(_ text: String, size: CGFloat, fontName: String, tracking: CGFloat = 0) -> OutlinedRun {
  let font = CTFontCreateWithName(fontName as CFString, size, nil)
  let attributed = NSAttributedString(string: text, attributes: [
    NSAttributedString.Key(kCTFontAttributeName as String): font,
    NSAttributedString.Key(kCTKernAttributeName as String): tracking,
  ])
  let line = CTLineCreateWithAttributedString(attributed)
  let width = CTLineGetTypographicBounds(line, nil, nil, nil)
  let runs = CTLineGetGlyphRuns(line) as! [CTRun]
  var glyphIndex = 0
  var groups: [String: [String]] = [:]

  for run in runs {
    let count = CTRunGetGlyphCount(run)
    var glyphs = [CGGlyph](repeating: 0, count: count)
    var positions = [CGPoint](repeating: .zero, count: count)
    CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
    CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)

    for index in 0..<count {
      if let glyphPath = CTFontCreatePathForGlyph(font, glyphs[index], nil) {
        var transform = CGAffineTransform(translationX: positions[index].x, y: positions[index].y)
        if let positionedPath = glyphPath.copy(using: &transform) {
          let key = text == "R" ? "mark" : (text == "RallyUp" ? (glyphIndex < 5 ? "rally" : "up") : "text")
          groups[key, default: []].append(svgPath(positionedPath))
        }
      }
      glyphIndex += 1
    }
  }

  return OutlinedRun(width: width, groups: groups.mapValues { $0.joined(separator: " ") })
}

guard CommandLine.arguments.count > 2 else {
  fatalError("Pass Inter Black Italic and Inter Bold TTF paths as the first and second arguments.")
}
for argument in CommandLine.arguments.dropFirst() {
  let fontURL = URL(fileURLWithPath: argument)
  var registrationError: Unmanaged<CFError>?
  guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &registrationError) else {
    fatalError("Could not register Inter font: \(String(describing: registrationError?.takeRetainedValue()))")
  }
}
let output: [String: OutlinedRun] = [
  "wordmark": outline("RallyUp", size: 150, fontName: "Inter-BlackItalic"),
  "mark": outline("R", size: 208, fontName: "Inter-BlackItalic"),
  "tagline": outline("FIND YOUR MATCH.", size: 19, fontName: "Inter-Bold", tracking: 5.2),
]
let data = try JSONEncoder().encode(output)
print(String(data: data, encoding: .utf8)!)
