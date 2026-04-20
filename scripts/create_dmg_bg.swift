#!/usr/bin/env swift
// Generate DMG background image with drag-to-Applications arrow
import AppKit

let width: CGFloat = 660
let height: CGFloat = 400

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

let context = NSGraphicsContext.current!.cgContext

// Background gradient (dark gray)
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0),
        CGColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0),
    ] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: 0, y: 0), options: [])

// Arrow (center, pointing right)
let arrowY = height * 0.5
let arrowStartX: CGFloat = 250
let arrowEndX: CGFloat = 410
let arrowColor = NSColor(white: 1.0, alpha: 0.35)

// Arrow shaft
context.setStrokeColor(arrowColor.cgColor)
context.setLineWidth(2.5)
context.setLineCap(.round)
context.move(to: CGPoint(x: arrowStartX, y: arrowY))
context.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
context.strokePath()

// Arrow head
let headSize: CGFloat = 12
context.move(to: CGPoint(x: arrowEndX - headSize, y: arrowY + headSize))
context.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
context.addLine(to: CGPoint(x: arrowEndX - headSize, y: arrowY - headSize))
context.strokePath()

// Hint text at bottom
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor(white: 1.0, alpha: 0.3),
    .paragraphStyle: paragraphStyle,
]
let hint = "Drag Murmur to Applications to install"
let hintRect = NSRect(x: 0, y: 40, width: width, height: 30)
hint.draw(in: hintRect, withAttributes: attrs)

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create image")
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg_background.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Created: \(outputPath) (\(Int(width))x\(Int(height)))")
