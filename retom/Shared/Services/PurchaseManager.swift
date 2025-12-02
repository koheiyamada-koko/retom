// File: Shared/Services/PurchaseManager.swift
import Foundation
import StoreKit

/// StoreKit2を使った課金管理クラス
@MainActor
final class PurchaseManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Pro版を購入済みかどうか
    @Published var isProUser: Bool = false
    
    /// 購入処理中かどうか
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    /// プロダクトID（App Store Connectで設定するID）
    private let productID = "retom.pro"
    
    /// 購入済みトランザクションを監視するタスク
    private var updateListenerTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        // 起動時に購入状態を確認
        Task {
            await checkPurchaseStatus()
        }
        
        // トランザクション更新を監視
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 購入状態を確認（起動時や復元時に呼ぶ）
    func checkPurchaseStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        // 現在のトランザクションを確認
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    isProUser = true
                    return
                }
            }
        }
        
        isProUser = false
    }
    
    /// Pro版を購入
    func purchasePro() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // プロダクト情報を取得
        guard let product = try await Product.products(for: [productID]).first else {
            throw PurchaseError.productNotFound
        }
        
        // 購入処理
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // トランザクションを検証
            switch verification {
            case .verified(let transaction):
                // 購入成功
                await transaction.finish()
                isProUser = true
            case .unverified(_, let error):
                throw PurchaseError.verificationFailed(error)
            }
        case .userCancelled:
            throw PurchaseError.userCancelled
        case .pending:
            throw PurchaseError.pending
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    /// 購入を復元
    func restorePurchase() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // 現在のトランザクションを確認
        var foundPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    foundPro = true
                    break
                }
            }
        }
        
        if foundPro {
            isProUser = true
        } else {
            throw PurchaseError.noRestorablePurchases
        }
    }
    
    // MARK: - Private Methods
    
    /// トランザクション更新を監視
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                
                switch result {
                case .verified(let transaction):
                    if transaction.productID == self.productID {
                        await MainActor.run {
                            self.isProUser = true
                        }
                    }
                    await transaction.finish()
                case .unverified(_, let error):
                    print("⚠️ PurchaseManager: トランザクション検証失敗: \(error)")
                }
            }
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case productNotFound
    case verificationFailed(Error)
    case userCancelled
    case pending
    case noRestorablePurchases
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "プロダクトが見つかりませんでした"
        case .verificationFailed(let error):
            return "購入の検証に失敗しました: \(error.localizedDescription)"
        case .userCancelled:
            return "購入がキャンセルされました"
        case .pending:
            return "購入が保留中です"
        case .noRestorablePurchases:
            return "復元できる購入が見つかりませんでした"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}

