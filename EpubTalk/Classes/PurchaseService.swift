//
//  PurchaseService.swift
//  EpubTalk
//
//  Created by Fujiwara on 2015/07/13.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation
import StoreKit


//
// 課金管理クラス
//
class PurchaseService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    
    class var sharedInstance : PurchaseService {
        struct Static {
            static let instance : PurchaseService = PurchaseService()
        }
        return Static.instance
    }
    
    override init () {
        
    }
    
    deinit {
        
    }
    
    //
    // アプリ内課金が有効かどうか
    //
    func enableInAppPurchase()->Bool {

        return SKPaymentQueue.canMakePayments()
    }
    
    func startPurchase() {
        let set: NSSet = NSSet(object: Constants.kInAppPurchaseProductiId)
        let productRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: set as! Set<String>)
        productRequest.delegate = self
        productRequest.start()
    }
    
    
    //
    // MARK: SKProductsRequestDelegate
    //
    @objc func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        
    }
    
    
    //
    // MARK: SKPaymentTransactionObserver
    //
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            if let paymentTransaction = transaction as? SKPaymentTransaction {
                
                switch paymentTransaction.transactionState {
                case SKPaymentTransactionState.Purchasing:
                    break
                    
                case SKPaymentTransactionState.Purchased:
                    break
                    
                case SKPaymentTransactionState.Failed:
                    break
                    
                case SKPaymentTransactionState.Restored:
                    break
                    
                default:
                    break
                }
                
            }
        }
    }
    
    
    //
    // MARK: Private
    //
    
}