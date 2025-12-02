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

    // MARK: - レトロ調フィルタ（FUJI Classic Chrome風の色味・粒子・ビネット）

    private static func makeRetroCIImage(from input: CIImage) -> CIImage {
        var output = input

        // ① 色温度をクール寄りに調整（FUJI Classic Chrome風：わずかに青みを加える）
        do {
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = output
            temp.neutral = CIVector(x: 6500, y: 0)
            // 色温度を上げてクール寄りに（青みを加える）、グリーン寄りに微調整
            temp.targetNeutral = CIVector(x: 7200, y: -8)
            output = temp.outputImage ?? output
        }

        // ② 色チャンネル調整：緑と青を少し強調、赤を抑えめに（FUJIっぽい色バランス）
        do {
            if let colorMatrix = CIFilter(name: "CIColorMatrix") {
                colorMatrix.setValue(output, forKey: kCIInputImageKey)
                // 赤チャンネルを少し抑えめ（0.96倍）
                colorMatrix.setValue(CIVector(x: 0.96, y: 0, z: 0, w: 0), forKey: "inputRVector")
                // 緑チャンネルを少し強調（1.08倍）
                colorMatrix.setValue(CIVector(x: 0, y: 1.08, z: 0, w: 0), forKey: "inputGVector")
                // 青チャンネルを少し強調（1.06倍）
                colorMatrix.setValue(CIVector(x: 0, y: 0, z: 1.06, w: 0), forKey: "inputBVector")
                // アルファはそのまま
                colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
                // バイアスなし
                colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
                if let result = colorMatrix.outputImage {
                    output = result
                }
            }
        }

        // ③ トーンカーブ：ハイライトは飛ばさず、シャドウは潰さない（FUJIのトーン特性）
        do {
            let tone = CIFilter.toneCurve()
            tone.inputImage = output
            // シャドウを少し持ち上げ（潰さない）、ハイライトは控えめに
            tone.point0 = CGPoint(x: 0.0, y: 0.03)      // 黒を少し持ち上げ
            tone.point1 = CGPoint(x: 0.25, y: 0.20)     // シャドウ領域
            tone.point2 = CGPoint(x: 0.5, y: 0.50)      // ミッドトーン
            tone.point3 = CGPoint(x: 0.75, y: 0.80)     // ハイライト手前
            tone.point4 = CGPoint(x: 1.0, y: 0.95)      // ハイライトを飛ばさない
            output = tone.outputImage ?? output
        }

        // ④ 彩度・コントラスト調整（FUJI Classic Chrome風：やや強めのコントラスト、控えめな彩度）
        do {
            let controls = CIFilter.colorControls()
            controls.inputImage = output
            controls.saturation = 0.92    // 少し控えめだが、緑と青は鮮やかに見える
            controls.contrast = 1.12       // やや強めのコントラスト
            controls.brightness = 0.0     // 明るさは維持
            output = controls.outputImage ?? output
        }

        // ⑤ ランダムノイズを重ねてフィルム粒子っぽく
        do {
            let noise = CIFilter.randomGenerator()
            if let rawNoise = noise.outputImage?
                .cropped(to: input.extent)
                .applyingFilter(
                    "CIColorMatrix",
                    parameters: [
                        "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0.18),
                        "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0.18),
                        "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0.18),
                        "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
                    ]
                ) {

                let grainBlend = CIFilter.overlayBlendMode()
                grainBlend.inputImage = rawNoise
                grainBlend.backgroundImage = output
                if let blended = grainBlend.outputImage {
                    output = blended
                }
            }
        }

        // ⑥ 周辺減光（ビネット）
        do {
            let vignette = CIFilter.vignette()
            vignette.inputImage = output
            vignette.intensity = 0.9   // 強めの周辺減光
            vignette.radius = 2.0      // 半径（大きいほど緩やか）
            output = vignette.outputImage ?? output
        }

        // 元のサイズにクロップして返す
        return output.cropped(to: input.extent)
    }

    // MARK: - 日付スタンプ描画（7セグ風）

    private static func addDateStamp(to image: UIImage, date: Date) -> UIImage {
        let size = image.size
        let base = min(size.width, size.height)

        // 全体のスケール
        let digitHeight = base * 0.055         // 1桁の高さ
        let digitWidth  = digitHeight * 0.60   // 1桁の横幅
        let segThickness = digitHeight * 0.22  // セグメントの太さ
        let digitSpacing = digitWidth * 0.35   // 桁同士の間隔
        let margin       = base * 0.04         // 画面端からの余白

        // 例: "25 11 29" → "251129"
        let dateString = dateFormatter.string(from: date)
        let digitsOnly = dateString.replacingOccurrences(of: " ", with: "")

        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = image.scale
        rendererFormat.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)

        let stamped = renderer.image { ctx in
            // 元の画像
            image.draw(in: CGRect(origin: .zero, size: size))

            let context = ctx.cgContext

            // 7セグの色（赤LEDっぽい）
            let segmentColor = UIColor(red: 0.95, green: 0.25, blue: 0.18, alpha: 0.98)

            context.saveGState()

            // 右下を基準に座標系を移動
            let totalWidth =
                CGFloat(digitsOnly.count) * digitWidth +
                CGFloat(digitsOnly.count - 1) * digitSpacing +
                digitSpacing * 2    // 「25 11 29」のスペース用ちょいマージン

            let originX = size.width - margin - totalWidth
            let originY = size.height - margin - digitHeight

            var x = originX

            for (index, ch) in digitsOnly.enumerated() {
                let digitRect = CGRect(x: x, y: originY, width: digitWidth, height: digitHeight)
                drawSevenSegmentDigit(
                    ch,
                    in: digitRect,
                    context: context,
                    thickness: segThickness,
                    color: segmentColor
                )

                x += digitWidth + digitSpacing

                // 「25 11 29」みたいに 2桁ごとに少し余白を足す
                if index == 1 || index == 3 {
                    x += digitSpacing * 0.7
                }
            }

            context.restoreGState()
        }

        print("📷 stamped image size = \(stamped.size.width)x\(stamped.size.height)")
        return stamped
    }

    // MARK: - 7セグ数字の描画

    private static func drawSevenSegmentDigit(
        _ digit: Character,
        in rect: CGRect,
        context: CGContext,
        thickness: CGFloat,
        color: UIColor
    ) {
        // [a, b, c, d, e, f, g] の順でオン / オフ
        let segments: [Character: [Bool]] = [
            "0": [true,  true,  true,  true,  true,  true,  false],
            "1": [false, true,  true,  false, false, false, false],
            "2": [true,  true,  false, true,  true,  false, true ],
            "3": [true,  true,  true,  true,  false, false, true ],
            "4": [false, true,  true,  false, false, true,  true ],
            "5": [true,  false, true,  true,  false, true,  true ],
            "6": [true,  false, true,  true,  true,  true,  true ],
            "7": [true,  true,  true,  false, false, false, false],
            "8": [true,  true,  true,  true,  true,  true,  true ],
            "9": [true,  true,  true,  true,  false, true,  true ]
        ]

        guard let pattern = segments[digit] else { return }

        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        // thickness は外から来るけど、見た目バランス用に少し補正
        let segT = min(thickness, min(w, h) * 0.22)
        let corner = segT * 0.5

        context.setFillColor(color.cgColor)
        context.setShadow(
            offset: .zero,
            blur: segT * 1.2,
            color: UIColor.black.withAlphaComponent(0.7).cgColor
        )

        func drawSegment(_ frame: CGRect) {
            let path = UIBezierPath(roundedRect: frame, cornerRadius: corner)
            context.addPath(path.cgPath)
            context.fillPath()
        }

        // セグメントの共通サイズ計算
        let verticalHeight = (h - 3 * segT) / 2   // 上下の縦棒の高さ
        let topY     = y
        let middleY  = y + (h - segT) / 2
        let bottomY  = y + h - segT
        let leftX    = x
        let rightX   = x + w - segT

        // a: 上
        if pattern[0] {
            let frame = CGRect(
                x: x + segT,
                y: topY,
                width: w - 2 * segT,
                height: segT
            )
            drawSegment(frame)
        }

        // b: 右上
        if pattern[1] {
            let frame = CGRect(
                x: rightX,
                y: y + segT,
                width: segT,
                height: verticalHeight
            )
            drawSegment(frame)
        }

        // c: 右下
        if pattern[2] {
            let frame = CGRect(
                x: rightX,
                y: middleY + segT / 2,
                width: segT,
                height: verticalHeight
            )
            drawSegment(frame)
        }

        // d: 下
        if pattern[3] {
            let frame = CGRect(
                x: x + segT,
                y: bottomY,
                width: w - 2 * segT,
                height: segT
            )
            drawSegment(frame)
        }

        // e: 左下
        if pattern[4] {
            let frame = CGRect(
                x: leftX,
                y: middleY + segT / 2,
                width: segT,
                height: verticalHeight
            )
            drawSegment(frame)
        }

        // f: 左上
        if pattern[5] {
            let frame = CGRect(
                x: leftX,
                y: y + segT,
                width: segT,
                height: verticalHeight
            )
            drawSegment(frame)
        }

        // g: 真ん中
        if pattern[6] {
            let frame = CGRect(
                x: x + segT,
                y: middleY,
                width: w - 2 * segT,
                height: segT
            )
            drawSegment(frame)
        }
    }
}

