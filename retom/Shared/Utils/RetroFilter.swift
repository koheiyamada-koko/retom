// File: Shared/Utils/RetroFilter.swift
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct RetroFilter {

    private static let ciContext = CIContext()

    // 日付表示用フォーマッタ
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        // 好きなフォーマットに変えてOK
        // 例: "98 8 17" っぽくしたければ "yy M d"
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    /// メインの入口: 画像にレトロ加工 + 日付スタンプを付けて返す
    static func apply(to uiImage: UIImage, date: Date = Date()) -> UIImage {
        // 1. CIImage に変換
        guard let inputCI = CIImage(image: uiImage) else {
            return uiImage
        }

        // 2. ざっくりレトロな色味を作る（お好みで調整OK）
        let filteredCI = makeRetroCIImage(from: inputCI)

        // 3. CIImage -> UIImage に戻す
        guard let cgImage = ciContext.createCGImage(filteredCI, from: filteredCI.extent) else {
            return uiImage
        }
        let retroUIImage = UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)

        // 4. 日付スタンプを焼き込む
        let stamped = addDateStamp(to: retroUIImage, date: date)

        return stamped
    }

    // MARK: - レトロ調フィルタ（色味・ノイズなど）

    private static func makeRetroCIImage(from input: CIImage) -> CIImage {
        // コントラスト & 彩度を少し抑える
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = input
        colorControls.contrast = 1.1
        colorControls.saturation = 0.9
        colorControls.brightness = -0.02
        var output = colorControls.outputImage ?? input

        // 少しだけフィルムっぽい色ズレ
        if let chroma = CIFilter(name: "CIColorMatrix") {
            chroma.setValue(output, forKey: kCIInputImageKey)
            chroma.setValue(CIVector(x: 1.0, y: 0.0, z: 0.03, w: 0.0), forKey: "inputRVector")
            chroma.setValue(CIVector(x: 0.0, y: 1.0, z: -0.02, w: 0.0), forKey: "inputGVector")
            chroma.setValue(CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0), forKey: "inputBVector")
            if let o = chroma.outputImage {
                output = o
            }
        }

        // 軽いブラー（周辺が少し柔らかく見える程度）
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = output
        blur.radius = 0.8
        output = blur.outputImage?.clampedToExtent() ?? output

        return output
    }

    // MARK: - 日付スタンプ描画

    private static func addDateStamp(to image: UIImage, date: Date) -> UIImage {
        let size = image.size

        // 画像の短辺ベースで文字サイズを決める（縦横どちらでもバランスが取れるように）
        let base = min(size.width, size.height)
        let fontSize = base * 0.04       // 4%くらい
        let margin  = base * 0.03        // 3%くらい余白

        let dateString = dateFormatter.string(from: date)

        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = image.scale
        rendererFormat.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)

        let stampedImage = renderer.image { ctx in
            // 元の画像を描画
            image.draw(in: CGRect(origin: .zero, size: size))

            // 文字スタイル
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right

            // 影（フィルムのデジタル日付っぽい雰囲気用）
            let shadow = NSShadow()
            shadow.shadowBlurRadius = fontSize * 0.4
            shadow.shadowOffset = CGSize(width: 0, height: 0)
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.8)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular),
                .foregroundColor: UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 0.95), // オレンジ寄り
                .paragraphStyle: paragraph,
                .shadow: shadow
            ]

            // 描画サイズ・位置を計算（右下）
            let textSize = (dateString as NSString).size(withAttributes: attributes)
            let drawRect = CGRect(
                x: size.width - textSize.width - margin,
                y: size.height - textSize.height - margin,
                width: textSize.width,
                height: textSize.height
            )

            // 日付描画
            (dateString as NSString).draw(in: drawRect, withAttributes: attributes)
        }

        return stampedImage
    }
}

