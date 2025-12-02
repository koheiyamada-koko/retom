// File: Shared/Views/UpgradeView.swift
import SwiftUI

/// 無料版の撮影上限に達した時に表示するアップグレード画面
struct UpgradeView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // アイコン
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                // タイトル
                Text("無料版の撮影上限に達しました")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                // 説明文
                VStack(spacing: 12) {
                    Text("無料版では50枚まで撮影・保存できます。")
                    Text("続けて使うにはPro版（買い切り）へのアップグレードが必要です。")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                
                // 価格表示（オプション）
                Text("Pro版：¥300（税込・買い切り）")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                // ボタン
                VStack(spacing: 16) {
                    // Pro版にアップグレード
                    Button {
                        Task {
                            await purchasePro()
                        }
                    } label: {
                        HStack {
                            if purchaseManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Pro版にアップグレード")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(purchaseManager.isLoading)
                    
                    // 購入を復元
                    Button {
                        Task {
                            await restorePurchase()
                        }
                    } label: {
                        Text("購入を復元")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(purchaseManager.isLoading)
                    
                    // 閉じる
                    Button {
                        dismiss()
                    } label: {
                        Text("閉じる")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("アップグレード")
            .navigationBarTitleDisplayMode(.inline)
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func purchasePro() async {
        do {
            try await purchaseManager.purchasePro()
            // 購入成功したら閉じる
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func restorePurchase() async {
        do {
            try await purchaseManager.restorePurchase()
            // 復元成功したら閉じる
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

