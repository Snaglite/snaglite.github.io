import AppKit
// hero.swift mac.png ipad.png iphone.png out.png
let a = CommandLine.arguments
func cg(_ p: String) -> CGImage { var r = NSRect.zero; return NSImage(contentsOfFile: p)!.cgImage(forProposedRect: &r, context: nil, hints: nil)! }
let mac = cg(a[1]), ipad = cg(a[2]), phone = cg(a[3])
let W = 1800, H = 1030
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.interpolationQuality = .high
func place(_ img: CGImage, width: CGFloat, x: CGFloat, bottom: CGFloat) {
    let h = width * CGFloat(img.height) / CGFloat(img.width)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 50, color: CGColor(gray: 0, alpha: 0.45))
    ctx.draw(img, in: CGRect(x: x, y: bottom, width: width, height: h))
    ctx.restoreGState()
}
place(mac, width: 1400, x: 260, bottom: 160)      // Mac at the back
place(ipad, width: 520, x: 30, bottom: 20)        // iPad bottom left
place(phone, width: 300, x: 1440, bottom: 20)     // iPhone bottom right
try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[4]))
