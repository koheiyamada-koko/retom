// File: Shared/Utils/RetroFilter.swift
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct RetroFilter {

    // 共通 CI コンテキスト
    private static let ciContext = CIContext()

    // 日付表示用フォーマッタ（フィルムっぽい「25 11 23」スタイル）
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yy MM dd"
        return f
    }()

    /// メイン入口：レトロ加工 ＋ 右下に日付スタンプを焼き込んだ UIImage を返す
    static func apply(to uiImage: UIImage, date: Date = Date()) -> UIImage {
        print("🟡 RetroFilter.apply start")

        // 1. CIImage に変換
        guard let inputCI = CIImage(image: uiImage) else {
            print("❌ CIImage への変換に失敗。UIGraphics だけで日付を描画して返す")
            return addDateStamp(to: uiImage, date: date)
        }

        // 2. レトロ調フィルタ
        let filteredCI = makeRetroCIImage(from: inputCI)

        // 3. CIImage -> UIImage
        guard let cgImage = ciContext.createCGImage(filteredCI, from: filteredCI.extent) else {
            print("❌ createCGImage 失敗。元画像に日付だけ描画して返す")
            return addDateStamp(to: uiImage, date: date)
        }

        let retroUIImage = UIImage(
            cgImage: cgImage,
            scale: uiImage.scale,
            orientation: uiImage.imageOrientation
        )

        // 4. 日付スタンプ焼き込み
        let stamped = addDateStamp(to: retroUIImage, date: date)
        print("✅ RetroFilter.apply end")
        return stamped
    }

    // MARK: - レトロ調フィルタ（色味など）

    private static func makeRetroCIImage(from input: CIImage) -> CIImage {
        // コントラスト & 彩度
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = input
        colorControls.contrast = 1.1
        colorControls.saturation = 0.9
        colorControls.brightness = -0.02
        var output = colorControls.outputImage ?? input

        // ちょっと色ズレ
        if let chroma = CIFilter(name: "CIColorMatrix") {
            chroma.setValue(output, forKey: kCIInputImageKey)
            chroma.setValue(CIVector(x: 1.0, y: 0.0, z: 0.03, w: 0.0), forKey: "inputRVector")
            chroma.setValue(CIVector(x: 0.0, y: 1.0, z: -0.02, w: 0.0), forKey: "inputGVector")
            chroma.setValue(CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0), forKey: "inputBVector")
            if let o = chroma.outputImage {
                output = o
            }
        }

        // ごく軽いブラー
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = output
        blur.radius = 0.8
        output = blur.outputImage?.clampedToExtent() ?? output

        return output
    }

    // MARK: - 日付スタンプ描画（デジカメ風）

    private static func addDateStamp(to image: UIImage, date: Date) -> UIImage {
        let size = image.size

        // 画像の短辺ベースで文字サイズを決める
        let base = min(size.width, size.height)
        let fontSize = base * 0.045      // 少し大きめ
        let margin  = base * 0.035       // 余白も少し増やす

        let dateString = dateFormatter.string(from: date)

        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = image.scale
        rendererFormat.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)

        let stampedImage = renderer.image { ctx in
            // 元の画像を描画
            image.draw(in: CGRect(origin: .zero, size: size))

            // 右寄せ
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right

            // デジカメのLEDっぽい色（アンバー寄り）
            let textColor = UIColor(
                red: 1.0,
                green: 0.85,
                blue: 0.35,
                alpha: 0.98
            )

            // 影（少し強めにして光って見えるように）
            let shadow = NSShadow()
            shadow.shadowBlurRadius = fontSize * 0.45
            shadow.shadowOffset = CGSize(width: 0, height: 0)
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.9)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: textColor,
                .paragraphStyle: paragraph,
                .shadow: shadow,
                // 文字間隔を少し広げてデジタル表示感を出す
                .kern: fontSize * 0.12
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

