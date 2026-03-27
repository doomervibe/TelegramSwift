
import Foundation
import AppKit
import Strings

public extension NSColor {
    static func average(of colors: [NSColor]) -> NSColor {
        guard !colors.isEmpty else {
            return NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        }
        var sr: CGFloat = 0
        var sg: CGFloat = 0
        var sb: CGFloat = 0
        var sa: CGFloat = 0
        var n: CGFloat = 0
        for color in colors {
            guard let (r, g, b) = color.rgbTripletForColorMath() else { continue }
            sr += r
            sg += g
            sb += b
            sa += color.alpha
            n += 1
        }
        guard n > 0 else {
            return NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        }
        return NSColor(srgbRed: sr / n, green: sg / n, blue: sb / n, alpha: sa / n)
    }

    
    convenience init?(hexString: String) {
        let scanner = Scanner(string: hexString.prefix(7))
        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var num: UInt32 = 0
        var alpha: CGFloat = 1.0
        let checkSet = CharacterSet(charactersIn: "#0987654321abcdef")
        for char in hexString.lowercased().unicodeScalars {
            if !checkSet.contains(char) {
                return nil
            }
        }
        if scanner.scanHexInt32(&num), hexString.length >= 7 && hexString.length <= 9 {
            if hexString.length == 9 {
                let scanner = Scanner(string: hexString)
                scanner.scanLocation = 7
                var intAlpha: UInt32 = 0
                scanner.scanHexInt32(&intAlpha)
                alpha = CGFloat(intAlpha) / 255
            }
            self.init(num, alpha)
        } else {
            return nil
        }
    }
    
    
    convenience init(_ rgbValue:UInt32, _ alpha:CGFloat = 1.0) {
        let r: CGFloat = ((CGFloat)((rgbValue & 0xFF0000) >> 16))
        let g: CGFloat = ((CGFloat)((rgbValue & 0xFF00) >> 8))
        let b: CGFloat = ((CGFloat)(rgbValue & 0xFF))
        self.init(rgb: rgbValue, alpha: alpha)
        //self.init(srgbRed: r/255.0, green: g/255.0, blue: b/255.0, alpha: alpha)
       // self.init(deviceRed: r/255.0, green: g/255.0, blue: b/255.0, alpha: alpha)
    }
    
    var hexString: String {
        guard let (r, g, b) = rgbTripletForColorMath() else {
            return "#000000"
        }
        let a = alpha
        
        var rInt, gInt, bInt: Int
        var rHex, gHex, bHex: String
        
        var hexColor: String
        
        // Convert the components to numbers (unsigned decimal integer) between 0 and 255
        rInt = Int(round(r * 255.0))
        gInt = Int(round(g * 255.0))
        bInt = Int(round(b * 255.0))
        
        // Convert the numbers to hex strings
        rHex = rInt == 0 ? "00" : NSString(format:"%2X", rInt) as String
        gHex = gInt == 0 ? "00" : NSString(format:"%2X", gInt) as String
        bHex = bInt == 0 ? "00" : NSString(format:"%2X", bInt) as String
        
        rHex = rHex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        gHex = gHex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        bHex = bHex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if rHex.length == 1 {
            rHex = "0\(rHex)"
        }
        if gHex.length == 1 {
            gHex = "0\(gHex)"
        }
        if bHex.length == 1 {
            bHex = "0\(bHex)"
        }
        
        hexColor = rHex + gHex + bHex
        if a < 1 {
            return "#" + hexColor + ":\(String(format: "%.2f", Double(a * 100 / 100)))"
        } else {
            return "#" + hexColor
        }
    }
    
    var rgbHexString: String {
        guard let (r, g, b) = rgbTripletForColorMath() else {
            return "#000000"
        }
        
        var rInt, gInt, bInt: Int
        var rHex, gHex, bHex: String
        
        var hexColor: String
        
        // Convert the components to numbers (unsigned decimal integer) between 0 and 255
        rInt = Int(round(r * 255.0))
        gInt = Int(round(g * 255.0))
        bInt = Int(round(b * 255.0))
        
        // Convert the numbers to hex strings
        rHex = rInt == 0 ? "00" : NSString(format:"%2X", rInt) as String
        gHex = gInt == 0 ? "00" : NSString(format:"%2X", gInt) as String
        bHex = bInt == 0 ? "00" : NSString(format:"%2X", bInt) as String
        
        rHex = rHex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        gHex = gHex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        bHex = bHex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if rHex.length == 1 {
            rHex = "0\(rHex)"
        }
        if gHex.length == 1 {
            gHex = "0\(gHex)"
        }
        if bHex.length == 1 {
            bHex = "0\(bHex)"
        }
        
        hexColor = rHex + gHex + bHex
        return "#" + hexColor
    }
    
}


public extension NSColor {
    
    static func ==(lhs: NSColor, rhs: NSColor) -> Bool {
        return lhs.argb == rhs.argb
    }
    
    static func colorFromRGB(rgbValue:UInt32) ->NSColor {
         return NSColor.init(srgbRed: ((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0, green: ((CGFloat)((rgbValue & 0xFF00) >> 8))/255.0, blue: ((CGFloat)(rgbValue & 0xFF))/255.0, alpha: 1.0)
    }
    
    static func colorFromRGB(rgbValue:UInt32, alpha:CGFloat) ->NSColor {
        return NSColor.init(srgbRed: ((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0, green: ((CGFloat)((rgbValue & 0xFF00) >> 8))/255.0, blue: ((CGFloat)(rgbValue & 0xFF))/255.0, alpha:alpha)
    }
    
    var highlighted: NSColor {
        return self.withAlphaComponent(0.8)
    }
    
    var alpha: CGFloat {
        if let c = usingColorSpace(.sRGB) ?? usingColorSpace(.deviceRGB) {
            return c.alphaComponent
        }
        let n = cgColor.numberOfComponents
        if let comps = cgColor.components, n >= 1 {
            return comps[n - 1]
        }
        return 1
    }
    
    /// HSV with hue in 0…1 (matches `NSColor.getHue`). Computed from RGB — never calls `getHue`, which can raise `NSColorRaiseWithColorSpaceError` on some macOS versions.
    var hsv: (CGFloat, CGFloat, CGFloat) {
        guard let (r, g, b) = rgbTripletForColorMath() else {
            return (0, 0, 0)
        }
        return Self.hsvFromRGBTriplet(r, g, b)
    }
    
    func isTooCloseHSV(to color: NSColor) -> Bool {
        guard let (r1, g1, b1) = rgbTripletForColorMath(),
              let (r2, g2, b2) = color.rgbTripletForColorMath() else {
            return false
        }
        let hsv1 = Self.hsvFromRGBTriplet(r1, g1, b1)
        let hsv2 = Self.hsvFromRGBTriplet(r2, g2, b2)
        let sum1 = abs(hsv1.0) + abs(hsv1.1) + abs(hsv1.2)
        let sum2 = abs(hsv2.0) + abs(hsv2.1) + abs(hsv2.2)
        return abs(sum1 - sum2) < 0.005
    }

    var lightness: CGFloat {
        guard let (r, g, b) = rgbTripletForColorMath() else { return 0 }
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Same components as `hsv` (AppKit HSB == HSV); avoids `getHue`.
    var hsb: (CGFloat, CGFloat, CGFloat) {
        return hsv
    }

    
    var brightnessAdjustedColor: NSColor{
        if lightness > 0.7 {
            return NSColor(0x000000)
        } else {
            return NSColor(0xffffff)
        }
        var components = self.cgColor.components
        let alpha = components?.last
        components?.removeLast()
        let color = CGFloat(1-(components?.max())! >= 0.5 ? 1.0 : 0.0)
        return NSColor(red: color, green: color, blue: color, alpha: alpha!)
    }
    
    func withMultipliedBrightnessBy(_ factor: CGFloat) -> NSColor {
        let (h, s, v) = hsv
        let a = alpha
        let newV = max(0.0, min(1.0, v * factor))
        let (r, g, b) = Self.rgbFromHSVTriplet(h, s, newV)
        return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
    }
    
    func withMultiplied(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> NSColor {
        let (h0, s0, v0) = hsv
        let a = alpha
        let h2 = max(0.0, min(1.0, h0 * hue))
        let s2 = max(0.0, min(1.0, s0 * saturation))
        let v2 = max(0.0, min(1.0, v0 * brightness))
        let (r, g, b) = Self.rgbFromHSVTriplet(h2, s2, v2)
        return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
    }

    func interpolateTo(_ color: NSColor, fraction: CGFloat) -> NSColor? {
        let f = min(max(0, fraction), 1)
        guard let (r1, g1, b1) = rgbTripletForColorMath(),
              let (r2, g2, b2) = color.rgbTripletForColorMath() else {
            return self
        }
        let a1 = alpha
        let a2 = color.alpha
        let r = r1 + (r2 - r1) * f
        let g = g1 + (g2 - g1) * f
        let b = b1 + (b2 - b1) * f
        let a = a1 + (a2 - a1) * f
        return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
    }


    
    static var link:NSColor {
        return .colorFromRGB(rgbValue: 0x2481cc)
    }
    
    static var accent:NSColor {
        return .colorFromRGB(rgbValue: 0x2481cc)
    }
    
    static var redUI:NSColor {
        return colorFromRGB(rgbValue: 0xff3b30)
    }
    
    static var greenUI:NSColor {
        return colorFromRGB(rgbValue: 0x63DA6E)
    }
    
    static var blackTransparent:NSColor {
        return colorFromRGB(rgbValue: 0x000000, alpha: 0.6)
    }
    
    static var grayTransparent:NSColor {
        return colorFromRGB(rgbValue: 0xf4f4f4, alpha: 0.4)
    }
    
    static var grayUI:NSColor {
        return colorFromRGB(rgbValue: 0xFaFaFa, alpha: 1.0)
    }
    
    static var darkGrayText:NSColor {
        return NSColor(0x333333)
    }
    
    static var text:NSColor {
        return NSColor.black
    }
    
    
    static var blueText:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0x4ba3e2)
        }
    }
    
    static var accentSelect:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0x4c91c7)
        }
    }
    
    
    func lighter(amount : CGFloat = 0.15) -> NSColor {
        return hueColorWithBrightnessAmount(1 + amount)
    }
    
    func darker(amount : CGFloat = 0.15) -> NSColor {
        return hueColorWithBrightnessAmount(1 - amount)
    }
    
    private func hueColorWithBrightnessAmount(_ amount: CGFloat) -> NSColor {
        let (h, s, v) = hsv
        let a = alpha
        let newV = max(0.0, min(1.0, v * amount))
        let (r, g, b) = Self.rgbFromHSVTriplet(h, s, newV)
        return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
    }
    
    
    static var selectText:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0xeaeaea, alpha:1.0)
        }
    }
    
    static var random:NSColor  {
        get {
            return colorFromRGB(rgbValue: arc4random_uniform(16000000))
        }
    }
    
    static var blueFill:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0x4ba3e2)
        }
    }
    
    
    static var border:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0xeaeaea)
        }
    }
    
    
    
    static var grayBackground:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0xf4f4f4)
        }
    }
    
    static var grayForeground:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0xe4e4e4)
        }
    }
    
    
    
    static var grayIcon:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0x9e9e9e)
        }
    }
    
    
    static var accentIcon:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0x0f8fe4)
        }
    }
    
    static var badgeMuted:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0xd7d7d7)
        }
    }
    
    static var badge:NSColor  {
        get {
            return .blueFill
        }
    }
    
    static var grayText:NSColor  {
        get {
            return colorFromRGB(rgbValue: 0x999999)
        }
    }
}

public extension NSColor {
    convenience init(rgb: UInt32) {
        self.init(deviceRed: CGFloat((rgb >> 16) & 0xff) / 255.0, green: CGFloat((rgb >> 8) & 0xff) / 255.0, blue: CGFloat(rgb & 0xff) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: UInt32, alpha: CGFloat) {
        self.init(deviceRed: CGFloat((rgb >> 16) & 0xff) / 255.0, green: CGFloat((rgb >> 8) & 0xff) / 255.0, blue: CGFloat(rgb & 0xff) / 255.0, alpha: alpha)
    }
    
    convenience init(argb: UInt32) {
        self.init(deviceRed: CGFloat((argb >> 16) & 0xff) / 255.0, green: CGFloat((argb >> 8) & 0xff) / 255.0, blue: CGFloat(argb & 0xff) / 255.0, alpha: CGFloat((argb >> 24) & 0xff) / 255.0)
    }
    
    var argb: UInt32 {
        guard let (red, green, blue) = rgbTripletForColorMath() else {
            return 0xFF000000
        }
        let opa = self.alpha
        return (UInt32(opa * 255.0) << 24) | (UInt32(red * 255.0) << 16) | (UInt32(green * 255.0) << 8) | (UInt32(blue * 255.0))
    }
    
    var rgb: UInt32 {
        guard let (red, green, blue) = rgbTripletForColorMath() else {
            return 0x000000
        }
        return (UInt32(red * 255.0) << 16) | (UInt32(green * 255.0) << 8) | (UInt32(blue * 255.0))
    }
    
    var underTextColor: NSColor {
        return lightness > 0.8 ? NSColor(0x000000) : NSColor(0xffffff)
    }
}

fileprivate extension NSColor {
    /// Linear RGB (or gray) in a display-ish space for distance / HSV math — avoids `getHue`, which can throw ObjC exceptions on recent macOS.
    func rgbTripletForColorMath() -> (CGFloat, CGFloat, CGFloat)? {
        guard let srgb = usingColorSpace(.sRGB) ?? usingColorSpace(.displayP3) ?? usingColorSpace(.deviceRGB) else {
            return nil
        }
        let cg = srgb.cgColor
        guard let comps = cg.components, !comps.isEmpty else { return nil }
        let n = cg.numberOfComponents
        if n >= 3 {
            return (comps[0], comps[1], comps[2])
        }
        let w = comps[0]
        return (w, w, w)
    }

    /// Hue 0…1, saturation 0…1, value 0…1 — aligned with `NSColor.getHue(_:saturation:brightness:alpha:)`.
    static func hsvFromRGBTriplet(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        let maxV = max(max(r, g), b)
        let minV = min(min(r, g), b)
        let delta = maxV - minV
        let v = maxV
        let s = maxV > 0 ? delta / maxV : 0
        let h: CGFloat
        if delta == 0 {
            h = 0
        } else if maxV == r {
            var hh = (g - b) / delta
            hh = hh.truncatingRemainder(dividingBy: 6)
            if hh < 0 { hh += 6 }
            h = hh / 6
        } else if maxV == g {
            h = ((b - r) / delta + 2) / 6
        } else {
            h = ((r - g) / delta + 4) / 6
        }
        return (h, s, v)
    }

    /// Inverse of `hsvFromRGBTriplet`; `h` in 0…1, s/v in 0…1 — sRGB linear components in 0…1.
    static func rgbFromHSVTriplet(_ h: CGFloat, _ s: CGFloat, _ v: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        let vv = max(0, min(1, v))
        let ss = max(0, min(1, s))
        if ss <= 0 {
            return (vv, vv, vv)
        }
        var hh = h.truncatingRemainder(dividingBy: 1)
        if hh < 0 { hh += 1 }
        hh *= 6
        let i = floor(hh)
        let f = hh - i
        let p = vv * (1 - ss)
        let q = vv * (1 - f * ss)
        let t = vv * (1 - (1 - f) * ss)
        let pp = max(0, min(1, p))
        let qq = max(0, min(1, q))
        let tt = max(0, min(1, t))
        switch Int(i) % 6 {
        case 0: return (vv, tt, pp)
        case 1: return (qq, vv, pp)
        case 2: return (pp, vv, tt)
        case 3: return (pp, qq, vv)
        case 4: return (tt, pp, vv)
        default: return (vv, pp, qq)
        }
    }
}

public extension CGFloat {
    
    
    public static var cornerRadius:CGFloat {
        return 5
    }
    
    public static var borderSize:CGFloat  {
        get {
            return 1
        }
    }
    
   
    
}


