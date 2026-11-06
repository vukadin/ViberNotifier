//
//  NSImageExtensions.swift
//  ViberNotifier
//
//  Created by huikai on 2022/6/12.
//

import AppKit
import Foundation

extension NSImage {
    var png: Data? { tiffRepresentation?.bitmap?.png }

    func addBadgeToImage(drawText text: String, includingIcon: Bool = true) -> NSImage {
        let canvasWidth = defaultIconSize
        let canvasHeight = defaultIconSize
        let canvasSize = NSSize(width: canvasWidth, height: canvasHeight)
        let targetImage = NSImage(size: canvasSize, flipped: false) { (dstRect: CGRect) -> Bool in
            let iconSize = text.isEmpty ? defaultIconSize : defaultIconSize - 1
            if includingIcon {
                self.draw(in: CGRect(origin: .zero, size: NSSize(width: iconSize, height: iconSize)))
            }

            guard !text.isEmpty, Int(text) != nil else {
                return true
            }

            let textColor = NSColor.white
            let isLargeNumber = text.count > 1
            let finalText = isLargeNumber ? "9+" : text
            let textFont = NSFont.systemFont(ofSize: isLargeNumber ? 7 : 8, weight: .thin)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.center
            
            let textShadow = NSShadow()
            textShadow.shadowColor = NSColor.white.withAlphaComponent(0.35)
            textShadow.shadowOffset = NSSize(width: 0, height: -0.5)
            textShadow.shadowBlurRadius = 1
            
            let textFontAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: textColor,
                .shadow: textShadow
                ] as [NSAttributedString.Key : Any]

            let textRenderSize = (finalText as NSString).size(withAttributes: textFontAttributes)
            let maxAxisSizeForText = max(textRenderSize.width, textRenderSize.height)
            let badgeBackgroundSize = CGSize(width: maxAxisSizeForText + ( isLargeNumber ? 4 : 1 ), height: maxAxisSizeForText + 1)
            let badgeFillColor = NSColor(
                srgbRed: 241.0/255.0,
                green: 62.0/255.0,
                blue: 53.0/255.0,
                alpha: 1.0
            )
            let badgeBackgroundRect = CGRect(origin: CGPoint(x: canvasWidth - badgeBackgroundSize.width, y: 0), size: badgeBackgroundSize).integral
            let badgeBackgroundPath = NSBezierPath(
                roundedRect: badgeBackgroundRect,
                xRadius: 6,
                yRadius: 6
            )
            badgeFillColor.setFill()
            badgeBackgroundPath.fill()

            // Center text within the badge circle
            let textRect = CGRect(
                x: badgeBackgroundRect.midX - textRenderSize.width / 2,
                y: badgeBackgroundRect.midY - textRenderSize.height / 2,
                width: textRenderSize.width,
                height: textRenderSize.height
            )
            
            finalText.draw(in: textRect, withAttributes: textFontAttributes)

            return true
        }
        return targetImage
    }

    func grayOut() -> NSImage? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)

        guard let grayscale = bitmap.converting(to: .genericGray, renderingIntent: .default) else {
            return nil
        }

        let grayImage = NSImage(size: size)
        grayImage.addRepresentation(grayscale)
        return grayImage
    }

    func invert() -> NSImage? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)

        guard let filter = CIFilter(name: "CIColorInvert") else {
            print("Could not create CIColorInvert filter")
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            print("Could not obtain output CIImage from filter")
            return nil
        }

        let context = CIContext(options: nil)
        guard let cgOutImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return NSImage(cgImage: cgOutImage, size: size)
    }
}

extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
