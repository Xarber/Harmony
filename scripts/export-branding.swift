#!/usr/bin/env swift
// SPDX-License-Identifier: AGPL-3.0-only
import AppKit
let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "assets/branding")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
// Reproducible native rendering of the SVG master's simple geometry.
for size in [32, 180, 192, 512, 1024] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = CGFloat(size) / 1024
    let transform = NSAffineTransform(); transform.scale(by: scale); transform.concat()
    NSColor(srgbRed: 70/255, green: 77/255, blue: 206/255, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
    let background = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 1024, height: 1024), xRadius: 228, yRadius: 228)
    NSGradient(starting: NSColor(srgbRed: 133/255, green: 138/255, blue: 1, alpha: 1), ending: NSColor(srgbRed: 70/255, green: 77/255, blue: 206/255, alpha: 1))!.draw(in: background, angle: -45)
    NSColor.white.withAlphaComponent(0.11).setStroke()
    for radius in [340.0, 410.0] { let p = NSBezierPath(ovalIn: NSRect(x: 512-radius, y: 512-radius, width: radius*2, height: radius*2)); p.lineWidth = 2; p.stroke() }
    NSColor.white.setFill()
    for rect in [NSRect(x: 254, y: 300, width: 100, height: 424), NSRect(x: 670, y: 300, width: 100, height: 424), NSRect(x: 462, y: 216, width: 100, height: 592), NSRect(x: 328, y: 462, width: 368, height: 100)] { NSBezierPath(roundedRect: rect, xRadius: 50, yRadius: 50).fill() }
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("harmony-\(size).png"))
}

