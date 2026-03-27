//
//  Color.swift
//  TGUIKit
//
//  Created by keepcoder on 06/09/16.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Foundation
import AppKit
import ColorPalette

public class DashLayer : SimpleLayer {
    public override init() {
        super.init()
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    public var colors: PeerNameColors.Colors? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override func draw(in ctx: CGContext) {
        
        guard let colors = self.colors else {
            return
        }
        
        let radius: CGFloat = 3.0
        let lineWidth: CGFloat = 3.0

        
        let tintColor = colors.main
        let secondaryTintColor = colors.secondary
        let tertiaryTintColor = colors.tertiary
        
        
        ctx.setFillColor(tintColor.cgColor)
    
        let lineFrame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: lineWidth, height: frame.height))
        ctx.move(to: CGPoint(x: lineFrame.minX, y: lineFrame.minY + radius))
        ctx.addArc(tangent1End: CGPoint(x: lineFrame.minX, y: lineFrame.minY), tangent2End: CGPoint(x: lineFrame.minX + radius, y: lineFrame.minY), radius: radius)
        ctx.addLine(to: CGPoint(x: lineFrame.minX + radius, y: lineFrame.maxY))
        ctx.addArc(tangent1End: CGPoint(x: lineFrame.minX, y: lineFrame.maxY), tangent2End: CGPoint(x: lineFrame.minX, y: lineFrame.maxY - radius), radius: radius)
        ctx.closePath()
        ctx.clip()
        
        if let secondaryTintColor = secondaryTintColor {
            let isMonochrome = secondaryTintColor.alpha == 0.2

            do {
                ctx.saveGState()
                
                let dashHeight: CGFloat = tertiaryTintColor != nil ? 6.0 : 9.0
                let dashOffset: CGFloat
                if let _ = tertiaryTintColor {
                    dashOffset = isMonochrome ? -2.0 : 0.0
                } else {
                    dashOffset = isMonochrome ? -4.0 : 5.0
                }
            
                if isMonochrome {
                    ctx.setFillColor(tintColor.withMultipliedAlpha(0.2).cgColor)
                    ctx.fill(lineFrame)
                    ctx.setFillColor(tintColor.cgColor)
                } else {
                    ctx.setFillColor(tintColor.cgColor)
                    ctx.fill(lineFrame)
                    ctx.setFillColor(secondaryTintColor.cgColor)
                }
                
                func drawDashes() {
                    ctx.translateBy(x: 0, y: 0 + dashOffset)
                    
                    var offset = 0.0
                    while offset < frame.height {
                        ctx.move(to: CGPoint(x: 0.0, y: 3.0))
                        ctx.addLine(to: CGPoint(x: lineWidth, y: 0.0))
                        ctx.addLine(to: CGPoint(x: lineWidth, y: dashHeight))
                        ctx.addLine(to: CGPoint(x: 0.0, y: dashHeight + 3.0))
                        ctx.closePath()
                        ctx.fillPath()
                        
                        ctx.translateBy(x: 0.0, y: 18.0)
                        offset += 18.0
                    }
                }
                
                drawDashes()
                ctx.restoreGState()
                
                if let tertiaryTintColor = tertiaryTintColor{
                    ctx.saveGState()
                    ctx.translateBy(x: 0.0, y: dashHeight)
                    if isMonochrome {
                        ctx.setFillColor(tintColor.withAlphaComponent(0.4).cgColor)
                    } else {
                        ctx.setFillColor(tertiaryTintColor.cgColor)
                    }
                    drawDashes()
                    ctx.restoreGState()
                }
            }
        } else {
            ctx.setFillColor(tintColor.cgColor)
            ctx.fill(lineFrame)
        }
        
        ctx.resetClip()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Mirrors packages/Colors safe RGB→HSV math — avoids getHue/getRed ObjC exceptions on some macOS versions.
fileprivate extension NSColor {
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
    
    func withMultipliedAlpha(_ alpha: CGFloat) -> NSColor {
        guard let (r, g, b) = rgbTripletForColorMath() else {
            return withAlphaComponent(max(0.0, min(1.0, self.alpha * alpha)))
        }
        let a1 = self.alpha
        return NSColor(srgbRed: r, green: g, blue: b, alpha: max(0.0, min(1.0, a1 * alpha)))
    }
    
    func mixedWith(_ other: NSColor, alpha: CGFloat) -> NSColor {
        if let blended = self.blended(withFraction: alpha, of: other) {
            return blended
        }
        let mix = min(1.0, max(0.0, alpha))
        let oneMinus = 1.0 - mix
        guard let (r1, g1, b1) = rgbTripletForColorMath(),
              let (r2, g2, b2) = other.rgbTripletForColorMath() else {
            return self
        }
        let a1 = self.alpha
        let a2 = other.alpha
        let r = r1 * oneMinus + r2 * mix
        let g = g1 * oneMinus + g2 * mix
        let b = b1 * oneMinus + b2 * mix
        let a = a1 * oneMinus + a2 * mix
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


