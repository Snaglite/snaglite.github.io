// Puts an iPhone screenshot into the KeyCheck manual's iPhone frame.
// Usage, from the website folder:
//   swift tools/frame-keycheck-screenshot.swift tools/keycheck-iphone-frame.png <screenshot> keycheck/images/<name>.png
// The screenshot should be a full-screen iPhone 17 Pro screenshot (1206 × 2622), PNG or JPEG.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 4 else { print("Usage: frame-keycheck-screenshot <template.png> <screenshot> <output.png>"); exit(1) }
func image(_ path: String) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("Can't read \(path)"); exit(1) }
    return img
}
let frame = image(args[1]), shot = image(args[2])
// The screen inside the 780 × 1608 frame (same in CG's bottom-up coordinates, as it's centred vertically).
let screen = CGRect(x: 33, y: 28, width: 714, height: 1552)
let ratio = Double(shot.height) / Double(shot.width)
if abs(ratio - screen.height / screen.width) > 0.01 {
    print("Warning: \(shot.width) × \(shot.height) isn't the shape of an iPhone 17 Pro screen (1206 × 2622), so it will be stretched.")
}
guard let ctx = CGContext(data: nil, width: frame.width, height: frame.height, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
ctx.interpolationQuality = .high
ctx.draw(shot, in: screen)
ctx.draw(frame, in: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))

// The screenshot's square corners reach past the phone's rounded outline. Everything outside the phone
// (the frame's see-through pixels that join the image's edge) is put back exactly as the frame has it.
let w = frame.width, h = frame.height
var frameBytes = [UInt8](repeating: 0, count: w * h * 4)
guard let frameCtx = CGContext(data: &frameBytes, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                               space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
      let outBytes = ctx.data?.assumingMemoryBound(to: UInt8.self) else { exit(1) }
frameCtx.draw(frame, in: CGRect(x: 0, y: 0, width: w, height: h))
let rowBytes = ctx.bytesPerRow
var outside = [Bool](repeating: false, count: w * h)
var stack = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
while let (x, y) = stack.popLast() {
    guard x >= 0, y >= 0, x < w, y < h, !outside[y * w + x], frameBytes[(y * w + x) * 4 + 3] < 255 else { continue }
    outside[y * w + x] = true
    stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
}
for y in 0..<h { for x in 0..<w where outside[y * w + x] {
    for c in 0..<4 { outBytes[y * rowBytes + x * 4 + c] = frameBytes[(y * w + x) * 4 + c] }
} }
guard let out = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[3]) as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, out, nil)
CGImageDestinationFinalize(dest)
print("Framed \(args[3])")
