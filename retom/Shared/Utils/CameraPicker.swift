// File: Shared/Utils/CameraPicker.swift
import SwiftUI
import UIKit

/// UIKit のカメラ／フォトライブラリ画面を SwiftUI から使うためのラッパー
struct CameraPicker: UIViewControllerRepresentable {

    /// 画像が撮影・取得できたときに呼ばれるコールバック
    let onImagePicked: (UIImage) -> Void

    // MARK: - Coordinator

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        // ▶︎ シミュレータでは必ずフォトライブラリを使う
        #if targetEnvironment(simulator)
        picker.sourceType = .photoLibrary
        #else
        // ▶︎ 実機ではカメラがあればカメラ、なければフォトライブラリ
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        #endif

        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 画面更新時に特にやることはなし
    }
}

