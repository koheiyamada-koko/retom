// File: Shared/Utils/RetroFilter.swift
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct RetroFilter {

    private static let ciContext = CIContext()

    // 日付表示用フォーマッタ
    // IMG_8537 っぽい「'24 11 23」形式
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "''yy MM dd"   // 例: '24 11 23
        return f
    }()

    /// メインの入口: 画像にレトロ加工 + 日付スタンプを付けて返す
    static func apply(to uiImage: UIImage, date: Date = Date()) -> UIImage {

        // --- 1. レトロ調の色味を作る（失敗したら元画像をそのまま使う） ---
        let baseImage: UIImage

        if let inputCI = CIImage(image: uiImage) {
            let retroCI = makeRetroCIImage(from: inputCI)

            // blur などで広がった範囲を元の大きさに戻す
            let rect = inputCI.extent
            let cropped = retroCI.cropped(to: rect)

            if let cg = ciContext.createCGImage(cropped, from: rect) {
                baseImage = UIImage(
                    cgImage: cg,
                    scale: uiImage.scale,
                    orientation: uiImage.imageOrientation
                )
            } else {
                // ここに来たらフィルターは諦めて元画像を使う
                baseImage = uiImage
            }
        } else {
            baseImage = uiImage
        }

        // --- 2. 右下に日付を焼き込む（必ず実行） ---
        let stamped = addDateStamp(to: baseImage, date: date)
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
        output = blur.outputImage ?? output

        return output
    }

    // MARK: - 日付スタンプ描画（右下）

    private static func addDateStamp(to image: UIImage, date: Date) -> UIImage {
        let size = image.size

        // 画像の短辺ベースで文字サイズ・余白を決める
        let base = min(size.width, size.height)
        let fontSize = base * 0.06        // 6% くらい → かなり見える大きさ
        let margin  = base * 0.04        // 4% の余白

        let dateString = dateFormatter.string(from: date)

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let stampedImage = renderer.image { ctx in
            // 元の画像を描画
            image.draw(in: CGRect(origin: .zero, size: size))

            // 文字スタイル
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right

            // 影（フィルムのデジタル日付っぽい）
            let shadow = NSShadow()
            shadow.shadowBlurRadius = fontSize * 0.4
            shadow.shadowOffset = .zero
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.8)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: fontSize,
                                                        weight: .regular),
                .foregroundColor: UIColor(red: 1.0, green: 0.72, blue: 0.25, alpha: 1.0), // オレンジ寄り
                .paragraphStyle: paragraph,
                .shadow: shadow
            ]

            // 文字のサイズを計算
            let textSize = (dateString as NSString).size(withAttributes: attributes)

            // 描画位置（右下）
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

