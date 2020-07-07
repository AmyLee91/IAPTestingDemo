//
//  IAPHelper+StoreKit.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 06/07/2020.
//

import UIKit
import StoreKit

extension IAPHelper {

    /// Start the process to purchase a product. When we add the payment to the default payment queue
    /// StoreKit will present the required UI to the user and start processing the payment. When that
    /// transaction is complete or if a failure occurs, the payment queue sends the SKPaymentTransaction
    /// object that encapsulates the request to all transaction observers. See the
    /// paymentQueue(_:updatedTransactions) for how these events get handled.
    /// - Parameter product: An SKProduct object that describes the product to purchase.
    public func buyProduct(_ product: SKProduct) {
        guard !isPurchasing else { return }  // Don't allow another purchase to start until the current one completes

        let payment = SKPayment(product: product)  // Wrap the product in an SKPayment object
        isPurchasing = true
        SKPaymentQueue.default().add(payment)
    }
    
    /// Ask StoreKit to restore any previous purchases that are missing from this device.
    /// The user will be asked to authenticate. Will result in zero or more transactions
    /// to be received from the payment queue. See the SKPaymentTransactionObserver delegate.
    public func restorePurchases() {
        guard !isPurchasing else { return }  // Don't allow restore process to start until the current purchase completes

        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /// The Apple ID of some users (e.g. children) may not have permission to make purchases from the app store.
    /// - Returns: Returns true if the user is allowed to authorize payment, false if they do not have permission.
    public class func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }
}
