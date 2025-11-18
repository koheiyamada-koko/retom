// File: Shared/Utils/RetroFilter.swift
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct RetroFilter {
    private static let context = CIContext()

    /// 撮影画像にレトロフィルター＋日付スタンプを適用した UIImage を返す
    static func apply(to image: UIImage) -> UIImage {
        let filtered = applyCoreImageFilter(to: image)
        let stamped  = stampDate(on: filtered)
        return stamped
    }

    // MARK: - CoreImage でレトロ風フィルター

    private static func applyCoreImageFilter(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            return image
        }

        // ちょっと色あせたフィルム風
        let fade = CIFilter.photoEffectFade()
        fade.inputImage = ciImage

        guard let faded = fade.outputImage,
              let cgImage = context.createCGImage(faded, from: faded.extent)
        else {
            return image
        }

        // 向きは元画像に合わせる
        return UIImage(cgImage: cgImage,
                       scale: image.scale,
                       orientation: image.imageOrientation)
    }

    // MARK: - 右下に日付スタンプを描画

    private static func stampDate(on image: UIImage) -> UIImage {
        let format = DateFormatter()
        format.locale = Locale(identifier: "ja_JP")
        format.dateFormat = "yyyy.MM.dd"

        let dateText = format.string(from: Date())

        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 元画像をそのまま描画
            image.draw(in: CGRect(origin: .zero, size: size))

            // テキストスタイル
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.7)
            shadow.shadowOffset = CGSize(width: 1, height: 1)
            shadow.shadowBlurRadius = 2

            let fontSize = size.height * 0.035  // 画面高さに対して約3.5%
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: UIColor.white,
                .shadow: shadow
            ]

            let textSize = dateText.size(withAttributes: attributes)
            let margin: CGFloat = 20

            // どちらの向きでも「右下」になるように単純に右下に描く
            let origin = CGPoint(
                x: size.width - textSize.width - margin,
                y: size.height - textSize.height - margin
            )

            dateText.draw(at: origin, withAttributes: attributes)
        }
    }
}

