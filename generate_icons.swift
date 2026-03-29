#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO

let iconsetDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath + "/Sources/Resources/Assets.xcassets/AppIcon.appiconset"

let sourcePath = iconsetDir + "/AppIcon-1024.png"

guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: sourcePath) as CFURL, nil),
      let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    print("ERROR: Failed to load \(sourcePath)")
    exit(1)
}

print("Loaded source image: \(sourceImage.width)x\(sourceImage.height)")

struct IconEntry {
    let filename: String
    let pixels: Int
    let size: String
    let scale: String
    let idiom: String
}

let entries: [IconEntry] = [
    IconEntry(filename: "AppIcon-20@2x.png",    pixels: 40,   size: "20x20",     scale: "2x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-20@3x.png",    pixels: 60,   size: "20x20",     scale: "3x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-29@2x.png",    pixels: 58,   size: "29x29",     scale: "2x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-29@3x.png",    pixels: 87,   size: "29x29",     scale: "3x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-40@2x.png",    pixels: 80,   size: "40x40",     scale: "2x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-40@3x.png",    pixels: 120,  size: "40x40",     scale: "3x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-60@2x.png",    pixels: 120,  size: "60x60",     scale: "2x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-60@3x.png",    pixels: 180,  size: "60x60",     scale: "3x", idiom: "iphone"),
    IconEntry(filename: "AppIcon-76@1x.png",    pixels: 76,   size: "76x76",     scale: "1x", idiom: "ipad"),
    IconEntry(filename: "AppIcon-76@2x.png",    pixels: 152,  size: "76x76",     scale: "2x", idiom: "ipad"),
    IconEntry(filename: "AppIcon-83.5@2x.png",  pixels: 167,  size: "83.5x83.5", scale: "2x", idiom: "ipad"),
]

func resizeImage(_ src: CGImage, to pixels: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let ctx = CGContext(data: nil, width: pixels, height: pixels,
                               bitsPerComponent: 8, bytesPerRow: 0,
                               space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
    ctx.interpolationQuality = .high
    ctx.draw(src, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    return ctx.makeImage()
}

func savePNG(_ image: CGImage, to path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        return false
    }
    CGImageDestinationAddImage(dest, image, nil)
    return CGImageDestinationFinalize(dest)
}

var generated: [IconEntry] = []

for entry in entries {
    guard let resized = resizeImage(sourceImage, to: entry.pixels) else {
        print("WARN: Failed to resize \(entry.filename)")
        continue
    }
    let outPath = iconsetDir + "/" + entry.filename
    if savePNG(resized, to: outPath) {
        print("  ✓ \(entry.filename) (\(entry.pixels)x\(entry.pixels))")
        generated.append(entry)
    } else {
        print("WARN: Failed to write \(entry.filename)")
    }
}

// Build Contents.json
var images: [[String: String]] = []

// Existing universal 1024
images.append([
    "filename": "AppIcon-1024.png",
    "idiom": "universal",
    "platform": "ios",
    "size": "1024x1024"
])

// Add generated entries
for entry in generated {
    images.append([
        "filename": entry.filename,
        "idiom": entry.idiom,
        "scale": entry.scale,
        "size": entry.size
    ])
}

let contentsDict: [String: Any] = [
    "images": images,
    "info": ["author": "xcode", "version": 1]
]

let jsonData = try JSONSerialization.data(withJSONObject: contentsDict, options: [.prettyPrinted])
let contentsPath = iconsetDir + "/Contents.json"
try jsonData.write(to: URL(fileURLWithPath: contentsPath))
print("  ✓ Updated Contents.json with \(images.count) entries")
print("Done.")
