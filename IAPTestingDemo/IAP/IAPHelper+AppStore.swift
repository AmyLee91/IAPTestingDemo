//
//  IAPHelper+AppStore.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 06/07/2020.
//

import UIKit
import StoreKit

extension IAPHelper {
    
    /// Should be used only when the receipt is not present at the appStoreReceiptURL or when
    /// it cannot be successfully validated. The app store is requested to provide a new receipt,
    /// which will result in the user being asked to provide their App Store credentials.
    /// - Parameter completion:     Closure that will be called when the receipt has been refreshed.
    /// - Parameter notification:   An IAPNotification with a value of .receiptRefreshCompleted or .receiptRefreshFailed.
    public func refreshReceipt(completion: @escaping (_ notification: IAPNotification?) -> Void) {
        refreshReceiptCompletion = completion
        
        receiptRequest?.cancel()  // Cancel any existing pending requests
        receiptRequest = SKReceiptRefreshRequest()
        receiptRequest!.delegate = self
        receiptRequest!.start()  // Will notify through SKRequestDelegate requestDidFinish(_:)
        sendNotification(notification: .receiptRefreshInitiated)
    }
    
    /// Request from the App Store the collection of products that we've configured for sale in App Store Connect.
    /// Note that requesting product info will cause the App Store to provide a refreshed receipt. This will automatically
    /// cause the receipt to be validated.
    /// - Parameter forceRefresh:   If true any existing product collection will be disgarded and the
    ///                             app store will be requested to provide a fresh collection.
    /// - Parameter completion:     A closure that will be called when the results are returned from the App Store.
    /// - Parameter notification:   An IAPNotification with a value of .configurationNoProductIds,
    ///                             .requestProductsCompleted or .requestProductsFailed
    public func requestProductsFromAppStore(forceRefresh: Bool = false, completion: @escaping (_ notification: IAPNotification?) -> Void) {
        // Get localized info about our available in-app purchase products from the App Store
        requestProductsCompletion = completion  // Save the completion handler so it can be used in productsRequest(_:didReceive:)
        
        guard haveConfiguredProductIdentifiers else {
            DispatchQueue.main.async { completion(.configurationNoProductIds) }
            return
        }
        
        if products != nil {
            if !forceRefresh {
                // We already have a product list supplied by the App Store. Tell observers it's available
                sendNotification(notification: .requestProductsCompleted)
                DispatchQueue.main.async { completion(nil) }
                return  // No need to refresh the list
            } else {
                products!.removeAll()
            }
        }
        
        productsRequest?.cancel()  // Cancel any existing pending requests
        
        // Request a list of products from the App Store. We use this request to present localized
        // prices and other information to the user. The results are returned asynchronously
        // to the SKProductsRequestDelegate methods productsRequest(_:didReceive:) or
        // request(_:didFailWithError:). These delegate methods may or may not be called if
        // there's no network connection). If the results are returned successfully to
        // productsRequest(_:didReceive:) then it makes a call to validateReceiptAndGetProductsIds().
        productsRequest = SKProductsRequest(productIdentifiers: configuredProductIdentifiers!)
        productsRequest!.delegate = self
        productsRequest!.start()
        
        sendNotification(notification: .requestProductsInitiated)
    }
    
    /// Start the process to purchase a product. When we add the payment to the default payment queue
    /// StoreKit will present the required UI to the user and start processing the payment. When that
    /// transaction is complete or if a failure occurs, the payment queue sends the SKPaymentTransaction
    /// object that encapsulates the request to all transaction observers. See the
    /// paymentQueue(_:updatedTransactions) for how these events get handled.
    /// - Parameter product:        An SKProduct object that describes the product to purchase.
    /// - Parameter completion:     Completion block that will be called when the purchase has completed, failed or been cancelled.
    /// - Parameter notification:   An IAPNotification with a value of .purchaseCompleted, .purchaseCancelled or .purchaseFailed
    public func buyProduct(_ product: SKProduct, completion: @escaping (_ notification: IAPNotification?) -> Void) {
        guard !isPurchasing else { return }  // Don't allow another purchase to start until the current one completes

        purchaseCompletion = completion  // Save the completion block for later use
        
        let payment = SKPayment(product: product)  // Wrap the product in an SKPayment object
        isPurchasing = true
        SKPaymentQueue.default().add(payment)
    }
    
    /// Ask StoreKit to restore any previous purchases that are missing from this device.
    /// The user may be asked to authenticate. Will result in zero (if the user hasn't
    /// actually purchased anything) or more transactions to be received from the payment queue.
    /// See the SKPaymentTransactionObserver delegate.
    /// - Parameter completion:     Completion block that will be called when purchases have successfully restored or the process fails.
    /// - Parameter notification:   An IAPNotification with a value of .purchaseRestored or purchaseRestoreFailed
    public func restorePurchases(completion: @escaping (_ notification: IAPNotification?) -> Void) {
        guard !isPurchasing else { return }  // Don't allow restore process to start until the current purchase completes

        restorePurchasesCompletion = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /// The Apple ID of some users (e.g. children) may not have permission to make purchases from the app store.
    /// - Returns: Returns true if the user is allowed to authorize payment, false if they do not have permission.
    public class func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }
}
