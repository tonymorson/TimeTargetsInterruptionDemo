import Foundation
import UIKit

public extension UIColor {
  convenience init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat = 1) {
    let offset = saturation * (lightness < 0.5 ? lightness : 1 - lightness)
    let brightness = lightness + offset
    let saturation = lightness > 0 ? 2 * offset / brightness : 0
    self.init(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
  }

  var lighter: UIColor? {
    applying(lightness: 1.35)
  }

  var slightyLighter: UIColor? {
    applying(lightness: 1.50)
  }

  var darker: UIColor? {
    applying(lightness: 0.35)
  }

  var slightyDarker: UIColor? {
    applying(lightness: 0.50)
  }

  func applying(lightness value: CGFloat) -> UIColor? {
    guard let hsl = hsl else { return nil }
    return UIColor(hue: hsl.hue, saturation: hsl.saturation, lightness: hsl.lightness * value, alpha: hsl.alpha)
  }

  private var hsl: (hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat)? {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0, hue: CGFloat = 0
    guard
      getRed(&red, green: &green, blue: &blue, alpha: &alpha),
      getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
    else { return nil }
    let upper = max(red, green, blue)
    let lower = min(red, green, blue)
    let range = upper - lower
    let lightness = (upper + lower) / 2
    let saturation = range == 0 ? 0 : range / (lightness < 0.5 ? lightness * 2 : 2 - lightness * 2)
    return (hue, saturation, lightness, alpha)
  }
}
