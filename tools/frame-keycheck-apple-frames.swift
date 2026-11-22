import AppKit
// frame.swift frame.png shot.png x y out.png outWidth [paintCorner]
let a = CommandLine.arguments
func cg(_ p: String) -> CGImage { var r = NSRect.zero; return NSImage(contentsOfFile: p)!.cgImage(forProposedRect: &r, context: nil, hints: nil)! }
let frame = cg(a[1]), shot = cg(a[2])
let x = CGFloat(Double(a[3])!), y = CGFloat(Double(a[4])!)
let W = frame.width, H = frame.height
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let rect = CGRect(x: x, y: CGFloat(H) - y - CGFloat(shot.height), width: CGFloat(shot.width), height: CGFloat(shot.height))
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: rect, cornerWidth: CGFloat(Double(ProcessInfo.processInfo.environment["R"] ?? "60")!), cornerHeight: CGFloat(Double(ProcessInfo.processInfo.environment["R"] ?? "60")!), transform: nil)); ctx.clip()
ctx.draw(shot, in: rect)
if a.count > 7 { ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: rect.maxX - 120, y: rect.minY, width: 120, height: 90)) }
ctx.restoreGState()
ctx.draw(frame, in: CGRect(x: 0, y: 0, width: W, height: H))
let full = ctx.makeImage()!
let ow = Int(a[6])!, oh = Int(Double(H) * Double(ow) / Double(W))
let small = CGContext(data: nil, width: ow, height: oh, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
small.interpolationQuality = .high
small.draw(full, in: CGRect(x: 0, y: 0, width: ow, height: oh))
try! NSBitmapImageRep(cgImage: small.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[5]))
