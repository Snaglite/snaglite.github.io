import AppKit
// desk.swift window.png nativeWidth out.png  -> 3024x1964 screen with window centred on a soft gradient
let a = CommandLine.arguments
var r = NSRect.zero
let win = NSImage(contentsOfFile: a[1])!.cgImage(forProposedRect: &r, context: nil, hints: nil)!
let W = 3024, H = 1964
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [CGColor(red: 0.55, green: 0.70, blue: 0.92, alpha: 1), CGColor(red: 0.80, green: 0.86, blue: 0.95, alpha: 1)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 0), end: CGPoint(x: W, y: H), options: [])
let ww = CGFloat(Double(a[2])!), wh = ww * CGFloat(win.height) / CGFloat(win.width)
let rect = CGRect(x: (CGFloat(W) - ww) / 2, y: (CGFloat(H) - 74 - wh) / 2, width: ww, height: wh)
ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 90, color: CGColor(gray: 0, alpha: 0.35))
ctx.interpolationQuality = .high
ctx.draw(win, in: rect)
try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[3]))
