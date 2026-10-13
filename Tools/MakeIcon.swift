import AppKit

// Render actual macOS emoji, keeping the requested three-cube design deterministic.
let output = CommandLine.arguments[1]
let side = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
let rect = NSRect(x: 40, y: 40, width: 944, height: 944)
let path = NSBezierPath(roundedRect: rect, xRadius: 211, yRadius: 211)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedRed: 0.13, green: 0.41, blue: 0.64, alpha: 0.2)
shadow.shadowBlurRadius = 20
shadow.shadowOffset = NSSize(width: 0, height: -8)
shadow.set()
NSColor.white.setFill()
path.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(colors: [NSColor(calibratedRed: 0.29, green: 0.69, blue: 0.96, alpha: 1), NSColor(calibratedRed: 0.77, green: 0.92, blue: 1, alpha: 1), .white])!.draw(in: path, angle: 60)
NSColor.white.withAlphaComponent(0.7).setStroke()
path.lineWidth = 3
path.stroke()
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont(name: "Apple Color Emoji", size: 410)!]
let cube = "🧊" as NSString
cube.draw(at: NSPoint(x: 303, y: 405), withAttributes: attrs)
cube.draw(at: NSPoint(x: 140, y: 163), withAttributes: attrs)
cube.draw(at: NSPoint(x: 464, y: 151), withAttributes: attrs)
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
