#!/usr/bin/env swift
// Generate DMG background image — dark background with dashed arrow, no text labels
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
let arrowY = height * 0.52
let arrowStartX: CGFloat = 240
let arrowEndX: CGFloat = 420
let arrowColor = NSColor(white: 1.0, alpha: 0.3)

// Dashed arrow shaft
context.setStrokeColor(arrowColor.cgColor)
context.setLineWidth(2)
context.setLineCap(.round)
context.setLineDash(phase: 0, lengths: [8, 6])
context.move(to: CGPoint(x: arrowStartX, y: arrowY))
context.addLine(to: CGPoint(x: arrowEndX - 2, y: arrowY))
context.strokePath()

// Arrow head (solid)
context.setLineDash(phase: 0, lengths: [])
let headSize: CGFloat = 10
context.move(to: CGPoint(x: arrowEndX - headSize, y: arrowY + headSize))
context.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
context.addLine(to: CGPoint(x: arrowEndX - headSize, y: arrowY - headSize))
context.strokePath()

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
