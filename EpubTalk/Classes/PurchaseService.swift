//
//  PurchaseService.swift
//  EpubTalk
//
//  Created by Fujiwara on 2015/07/13.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation
import StoreKit

// 購入種別
enum PurchaseStatus: Int {
    case NotPurcased,   // 未課金
    Purchased,          // 課金済み
    NeedRestore
}

// 課金種別
enum PurchaseType: Int {
    case Unknown = 0
    case Payment = 1
    case Restore = 2
}


//
// 課金管理クラス
//
class PurchaseService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    private var purchaseType: PurchaseType
    private var didPurchaseSuccess: (()->Void)?
    private var didRestoreSuccess: (()->Void)?
    private var didPurchaseFailure: ((errorCode: TTErrorCode)->Void)?

    
    class var sharedInstance : PurchaseService {
        struct Static {
            static let instance : PurchaseService = PurchaseService()
        }
        return Static.instance
    }
    
    override init () {
        self.purchaseType = PurchaseType.Unknown
        self.didPurchaseSuccess = nil
        self.didRestoreSuccess = nil
        self.didPurchaseFailure = nil
    }
    
    deinit {
        
    }
    
    // 課金済みステータスを取得する
    static func getPurchaseStatus()->PurchaseStatus {
        return PurchaseStatus(rawValue: PurchaseService.getStatus())!
    }
    
    //
    // アプリ内課金が有効かどうか
    //
    func enableInAppPurchase()->Bool {

        return SKPaymentQueue.canMakePayments()
    }
    
    //
    // 購入処理開始
    //
    func startPurchase(didSuccess: (()->Void), didFailure: ((errorCode: TTErrorCode)->Void)) {
        self.purchaseType = PurchaseType.Payment
        self.didPurchaseSuccess = didSuccess
        self.didPurchaseFailure = didFailure
        
        if !self.enableInAppPurchase() {
            didFailure(errorCode: .FailedToPurchase)
            return
        }
        self.startPurchaseRequest()
    }

    //
    // リストア処理開始
    //
    func startRestore(didSuccess: (()->Void), didFailure: ((errorCode: TTErrorCode)->Void)) {
        self.purchaseType = PurchaseType.Restore
        self.didRestoreSuccess = didSuccess
        self.didPurchaseFailure = didFailure
        
        if !self.enableInAppPurchase() {
            didFailure(errorCode: .FailedToPurchase)
            return
        }
        self.startPurchaseRequest()
    }
    
    
    //
    // MARK: SKProductsRequestDelegate
    //
    @objc func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        Log(NSString(format: "products:%@", response.products))
        // 無効なアイテム
        if response.invalidProductIdentifiers.count > 0 {
            LogE(NSString(format: "Invalid product id. %@", response.invalidProductIdentifiers))
            self.didPurchaseFailure!(errorCode: .FailedToPurchase)
            return
        }
        
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        for product: SKProduct in response.products {
            switch self.purchaseType {
            case .Payment:
                SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: product))
            case .Restore:
                SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
            default:
                break
            }
        }
    }
    
    
    //
    // MARK: SKPaymentTransactionObserver
    //
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        Log(NSString(format: "transactions:%@", transactions))
        
        for transaction: SKPaymentTransaction in transactions {
            
            switch transaction.transactionState {
            case SKPaymentTransactionState.Purchasing:
                LogM("Purchasing...")
                break
                
            case SKPaymentTransactionState.Purchased:
                LogM("Success To Purchase.")
                // リクエストと合っていれば保存
                if self.purchaseType == PurchaseType.Payment {
                    PurchaseService.saveStatus(PurchaseStatus.Purchased)
                    queue.finishTransaction(transaction)
                }
                break
                
            case SKPaymentTransactionState.Failed:
                LogE(NSString(format: "Failed to purchase. %@", transaction))
                self.didPurchaseFailure!(errorCode: .CanceledToPurchase)
                return
                
            case SKPaymentTransactionState.Restored:
                if self.purchaseType == PurchaseType.Restore {
                    queue.finishTransaction(transaction)
                }
                break
                
            default:
                break
            }
        }
    }
    
    //
    // リストア完了
    //
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        LogM("Finish transaction.")
        didRestoreSuccess!()
    }
    
    //
    // リストアに失敗
    //
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        LogE(NSString(format:"Failed to restore completed. code:%d description:%@", error.code, error.description))
        didPurchaseFailure!(errorCode: .FailedToRestore)
    }
    
    
    //
    // MARK: Private
    //
 
    func startPurchaseRequest() {
        let set: NSSet = NSSet(object: Constants.kInAppPurchaseProductiId)
        let productRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: set as! Set<String>)
        productRequest.delegate = self
        productRequest.start()
    }
    
    static private func getStatus()->Int {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        return defaults.integerForKey(Constants.kSavePurchaseStatusKey)
    }
    
    static private func saveStatus(status: PurchaseStatus) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(status.rawValue, forKey: Constants.kSavePurchaseStatusKey)
        defaults.synchronize()
    }
}