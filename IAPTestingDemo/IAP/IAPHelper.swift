//
//  IAPHelper.swift
//  Writerly
//
//  Created by Russell Archer on 16/10/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

public typealias ProductId = String

/// Make sure to 
public class IAPHelper: NSObject  {
    
    // MARK:- Public Properties
    
    /// Singleton access
    public static let shared: IAPHelper = IAPHelper()

    public var purchasesValid       = false  // True if the fallback and receipt purchases agree
    public var isPurchasing         = false  // True if a purchase is in progress (excluding a deferred)
    public var addedToPaymentQueue  = false  // True if we've added ourselves to the SKPaymentQueue

    /// List of products retrieved from the App Store and available for purchase
    public var products: [SKProduct]?
    
    /// List of ProductIds that are read from the .storekit configuration file
    public var configuredProductIdentifiers: Set<ProductId>?
    
    /// This property is set automatically when IAPHelper is initialized and contains the set of
    /// all products purchased by the user. The collection is not persisted but is rebuilt from the
    /// product identifiers of purchased products stored individually in user defaults (see IAPPersistence).
    /// This is a fall-back collection of purchases designed to allow the user access to purchases
    /// in the event that the app receipt is missing and we can't contact the App Store to refresh it.
    public var fallbackPurchasedProductIdentifiers: Set<ProductId>?
    
    /// True if we have a list of unvalidated purchased product IDs. See fallbackPurchasedProductIdentifiers
    public var haveFallbackPurchasedProductIdentifiers: Bool {
        guard fallbackPurchasedProductIdentifiers != nil else { return false }
        return fallbackPurchasedProductIdentifiers!.count > 0 ? true : false
    }
    
    /// True if we have a list of ProductIds read from the .storekit configuration file. See configuredProductIdentifiers
    public var haveConfiguredProductIdentifiers: Bool {
        guard configuredProductIdentifiers != nil else { return false }
        return configuredProductIdentifiers!.count > 0 ? true : false
    }
    
    /// True if app store product info has been retrieved via requestProducts()
    public var isAppStoreProductInfoAvailable: Bool {
        guard products != nil else { return false }
        guard products!.count > 0 else { return false }
        return true
    }
    
    // MARK:- Private Properties

    fileprivate var receipt: IAPReceipt!                                     // Represents the app store receipt located in the main bundle
    fileprivate var productsRequest: SKProductsRequest?                      // Used to request product info async from the App Store
    fileprivate var receiptRequest: SKRequest?                               // Used to request a receipt refresh async from the App Store
    fileprivate var refreshReceiptCompletion: ((IAPError?) -> Void)? = nil   // Used when requesting a refreshed receipt from the app store
    fileprivate var requestProductsCompletion: ((IAPError?) -> Void)? = nil  // Used when requesting products from the app store
    
    // MARK:- Initialization
    
    /// Private initializer prevents more than a single instance of this class being created.
    /// See the public static 'shared' property
    private override init() {
        super.init()
        setup()
    }
    
    // MARK:- Configuration
    
    internal func setup() {
        receipt = IAPReceipt()
        
        addToPaymentQueue()
        readConfigFile()
        loadFallbackProductIds()
        
        guard receipt.isReachable,
              receipt.load(),
              receipt.validateSigning(),
              receipt.read(),
              receipt.validate() else {
            
            IAPLog.event(error: receipt.mostRecentError)
            sendNotification(notification: .receiptValidationFailed)
            return
        }
        
        sendNotification(notification: .receiptValid)
        createValidatedFallbackProductIds()
    }
    
    internal func addToPaymentQueue() {
        // Add ourselves as an observer of the StoreKit payments queue. This allows us to receive
        // notifications for when payments are successful, fail, are restored, etc.
        // See the SKPaymentQueue notification handler paymentQueue(_:updatedTransactions:) below
        if addedToPaymentQueue { return }
        SKPaymentQueue.default().add(self)
        addedToPaymentQueue = true
    }
    
    internal func readConfigFile() {
        // Read our configuration file that contains the list of ProductIds that are available on the App Store
        configuredProductIdentifiers = nil
        let result = IAPConfiguration.read(filename: IAPConstants.File(), ext: IAPConstants.FileExt())
        switch result {
            case .failure(let error):
                IAPLog.event(error: error)
                
            case .success(let configuration):
                guard let configuredProducts = configuration.products, configuredProducts.count > 0 else { break }
                configuredProductIdentifiers = Set<ProductId>(configuredProducts.compactMap { product in product.productID })
        }
    }
    
    internal func loadFallbackProductIds() {
        // Load our fallback list of purchased ProductIds
        guard haveConfiguredProductIdentifiers else { return }
        
        fallbackPurchasedProductIdentifiers = IAPPersistence.loadPurchasedProductIds(for: configuredProductIdentifiers!)
        if fallbackPurchasedProductIdentifiers == nil {
            // This not an error. It just means that nothing's yet been purchased, or that somehow the
            // fallback list of purchased ProductIds store in UserDefaults has been wiped. The fallback
            // list will be recreated and persisted after validating the App Store receipt
            IAPLog.event(error: .purchasedFallbackListMissingOrEmpty)
        }
    }
    
    // MARK:- Receipt
    
    /// Should be used only when the receipt is not present at the appStoreReceiptURL or when
    /// it cannot be successfully validated. The app store is requested to provide a new receipt,
    /// which will result in the user being asked to provide their App Store credentials.
    internal func refreshReceipt(completion: @escaping (IAPError?) -> Void) {
        refreshReceiptCompletion = completion
        
        receiptRequest?.cancel()  // Cancel any existing pending requests
        receiptRequest = SKReceiptRefreshRequest()
        receiptRequest!.delegate = self
        receiptRequest!.start()  // Will notify through SKRequestDelegate requestDidFinish(_:)
    }
    
    // MARK:- APP Store
    
    internal func requestProductsFromAppStore(completion: @escaping (IAPError?) -> Void) {
        // Get localized info about our available in-app purchase products from the App Store
        requestProductsCompletion = completion  // Save the completion handler so it can be used in productsRequest(_:didReceive:)
        
        guard haveConfiguredProductIdentifiers else {
            completion(.noPreconfiguredProductIds)
            return
        }
        
        if products != nil {
            // We already have a product list supplied by the App Store. Tell observers it's available
            sendNotification(notification: .requestProductsCompleted)
            completion(nil)
            return  // No need to refresh the list
        }

        productsRequest?.cancel()  // Cancel any existing pending requests

        // Request a list of products from the App Store. We use this request to present localized
        // prices and other information to the user. The results are returned asynchronously
        // to the SKProductsRequestDelegate methods productsRequest(_:didReceive:) or
        // request(_:didFailWithError:). These delegate methods may or may not be called if
        // there's no network connection). If the results are returned successfully to
        // productsRequest(_:didReceive:) then it makes a call to validateReceiptAndGetProductsIds()
        productsRequest = SKProductsRequest(productIdentifiers: configuredProductIdentifiers!)
        productsRequest!.delegate = self
        productsRequest!.start()
        
        sendNotification(notification: .requestProductsInitiated)
    }

    // MARK:- Helpers
    
    /// Helper to enable an object to quickly observe all IAP-related notifications
    public func addObserverForNotifications(observer: Any, selector: Selector) {
        for key in IAPNotificaton.keys() {
            NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: key), object: nil)
        }
    }
    
    /// Helper to enable an object to observe an IAP-related notification
    public func addObserverForNotification(notification: IAPNotificaton, observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: notification.key()), object: nil)
    }

    /// Helper to enable an object to quickly remove itself as an observer of all IAP-related notifications
    public func removeObserverForNotifications(observer: Any) {
        for key in IAPNotificaton.keys() {
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: key), object: nil)
        }
    }
    
    /// Helper to enable an object to remove itself as an observer of an IAP-related notification
    public func removeObserverFor(notification: IAPNotificaton, observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: notification.key()), object: nil)
    }

    /// Returns an SKProduct given a ProductId. Product info is only available if isStoreProductInfoAvailable is true
    public func getStoreProductFrom(id: ProductId) -> SKProduct? {
        guard isAppStoreProductInfoAvailable else { return nil }
        for p in products! { if p.productIdentifier == id { return p } }
        return nil
    }
    
    /// Returns true if the product identified by the ProductId has been purchased
    public func isProductPurchased(id: ProductId) -> Bool {
        guard isAppStoreProductInfoAvailable else { return false }
        
        // There are two strategies we use to determine if a product has been successfully purchased:
        //
        //   1. We validate the App Store-issued Receipt, which is stored in our main bundle. This receipt
        //      is updated and reissued as necessary (for example, when there's a purchase) by the App Store.
        //      The data in the receipt gives a list of purchased products
        //
        //   2. We keep a 'fallback' list of ProductIDs for purchased products. This list is persisted to
        //      UserDefaults. We use this list in case we can't use method 1. above. This can happen when
        //      the receipt is missing, or hasn't yet been issued (i.e. the user hasn't purchased anything).
        //      The fallback list is also useful when we can't validate the receipt and can't request a
        //      new receipt from the App Store becuase of network connectivity issues, etc.
        //
        // When we validate the receipt we compare the fallback list of purchases with the more reliable
        // data from the receipt. If they disagree we re-write the list using info from the receipt.
        //todo
        return false
    }
    
    private func sendNotification(notification: IAPNotificaton, object: Any? = nil) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification.key()), object: object)
        IAPLog.event(event: notification)
    }
    
    private func createValidatedFallbackProductIds() {
        guard haveFallbackPurchasedProductIdentifiers, receipt.haveValidatedPurchasedProductIdentifiers else { return }
        
        if !receipt.validateFallbackProductIds(fallbackPids: fallbackPurchasedProductIdentifiers!) {
            IAPPersistence.resetPurchasedProductIds(
                from: fallbackPurchasedProductIdentifiers!,
                to: receipt.validatedPurchasedProductIdentifiers)
            
            fallbackPurchasedProductIdentifiers = receipt.validatedPurchasedProductIdentifiers
        }
        
        purchasesValid = true
    }
}

// MARK:- StoreKit

public extension IAPHelper {

    func buyProduct(_ product: SKProduct) {
        if isPurchasing { return }  // Don't allow another purchase to start until the current one completes

        let payment = SKPayment(product: product)  // Wrap the product in an SKPayment object
        isPurchasing = true

        // Add the payment to the default payment queue. StoreKit will present the required UI to the user
        // and start processing the payment. When that transaction is complete or if a failure occurs, the 
        // payment queue sends the SKPaymentTransaction object that encapsulates the request to all 
        // transaction observers. See our paymentQueue(_:updatedTransactions) for how these events get handled
        SKPaymentQueue.default().add(payment)
    }

    class func canMakePayments() -> Bool {
        // The Apple ID of some users (e.g. children) may not have permission to make purchases from the app store
        // Returns true if the user is allowed to authorize payment, false if they do not have permission
        return SKPaymentQueue.canMakePayments()
    }

    func restorePurchases() {
        // Ask StoreKit to restore any previous purchases that are missing from this device
        // The user will be asked to authenticate. Will result in zero or more transactions
        // to be received from the payment queue. See the SKPaymentTransactionObserver delegate below
        
        if isPurchasing { return }  // Don't allow restore process to start until the current purchase completes

        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK:- SKProductsRequestDelegate
//
// This delegate receives a list of localized product info from the App Store

extension IAPHelper: SKProductsRequestDelegate {

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count == 0 {
            IAPLog.event(error: .noProductsReturnedByAppStore)
            requestProductsCompletion?(.noProductsReturnedByAppStore)
            return
        }

        // Update our [SKProduct] set of all available products
        products = response.products

        // Send a notification to let observers know we have an updated set of products.
        sendNotification(notification: .requestProductsCompleted)
        
        productsRequest = nil  // Destroy the request object
        requestProductsCompletion?(nil)
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        sendNotification(notification: .requestProductsFailed)
        productsRequest = nil
    }
}

// MARK:- SKPaymentTransactionObserver
//
// This delegate allows us to receive notifications for when payments are successful, fail or are restored.

extension IAPHelper: SKPaymentTransactionObserver {

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:
                purchaseInProgress(transaction: transaction)

            case .purchased:
                purchaseCompleted(transaction: transaction)

            case .failed:
                purchaseFailed(transaction: transaction)

            case .restored:
                purchaseCompleted(transaction: transaction, restore: true)

            case .deferred:
                purchaseDeferred(transaction: transaction)
                
            default:
                fatalError()
            }
        }
    }
    
    /// New optional delegate method for iOS 11. Tells the observer that a user initiated an in-app purchase from the App Store
    /// (rather than via the app itself)
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        
        /*
         
         https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/PromotingIn-AppPurchases/PromotingIn-AppPurchases.html#//apple_ref/doc/uid/TP40008267-CH11-SW1
         
         When a user taps or clicks Buy on an in-app purchase on the App Store, StoreKit automatically opens your app and
         sends the transaction information to your app through the delegate method paymentQueue(_:shouldAddStorePayment:for).
         Your app must complete the purchase transaction and any related actions that are specific to your app.
         
         If your app is not installed when the user taps or clicks Buy, the App Store automatically downloads the app or
         prompts the user to buy it. The user gets a notification when the app installation is complete. This method is
         called when the user taps the notification.
         
         Otherwise, if the user opens the app manually, this method is called only if the app is opened soon after the
         purchase was started.
         
         You should make sure not to show popups or any other UI that will get in the way of the user purchasing the in-app
         purchase.
         
         Return true to continue the transaction, false to defer or cancel the transaction.
         
             * You should cancel (and provide feedback to the user) if the user has already purchased the product
             * You may wish to defer the purchase if the user is in the middle of something else critcial in your app.
         
         If you defer, you can re-start the transaction later by:
         
             * saving the payment passed to paymentQueue(_:shouldAddStorePayment:for)
             * returning false from paymentQueue(_:shouldAddStorePayment:for)
             * calling SKPaymentQueue.default().add(savedPayment) later to re-start the purchase
         
         Testing
         -------
         To test your promoted in-app purchases before your app is available in the App Store, Apple provides a system
         URL that triggers your app using the itms-services:// protocol.
         
             * Protocol: itms-services://
             * Parameter action: purchaseIntent
             * Parameter bundleId: bundle Id for your app (e.g. com.rarcher.writerly)
             * Parameter productIdentifier: the in-app purchase product name you want to test
         
         The URL looks like this:
         
         itms-services://?action=purchaseIntent&bundleId=com.company.appname&productIdentifier=product_name
         
         Examples for testing Writerly:
         
         itms-services://?action=purchaseIntent&bundleId=com.rarcher.writerly&productIdentifier=com.rarcher.writerly.waysintocharacter
         itms-services://?action=purchaseIntent&bundleId=com.rarcher.writerly&productIdentifier=com.rarcher.writerly.ayearofprompts
         
         Send this URL to yourself in an email or iMessage and open it from your device. You will know the test is
         running when your app opens automatically. You can then test your promoted in-app purchase.
         
         */
        
        // Has the IAP product already been purchased?
//        if isProductPurchased(product.productIdentifier) {
//            showMessage(msg: "You have already purchased \(product.localizedTitle)", title: "Purchase Cancelled")
//            return false  // Tell the store not to proceed with purchase
//        }

        return true  // Return true to continue the transaction (will result in normal processing via paymentQueue(_:updatedTransactions:)
    }

    fileprivate func purchaseCompleted(transaction: SKPaymentTransaction, restore: Bool = false) {
        // The purchase was successful. Allow the user access to the product

        isPurchasing = false
        guard let identifier = restore ?
            transaction.original?.payment.productIdentifier :
            transaction.payment.productIdentifier else { return }

        // Send a local notification about the purchase
        let notification = restore ? IAPNotificaton.purchaseRestored : IAPNotificaton.purchaseCompleted
        sendNotification(notification: notification, object: identifier)

        // Important: Remove the completed transaction from the queue. If this isn't done then
        // when the app restarts the payment queue will attempt to process the same transaction
        SKPaymentQueue.default().finishTransaction(transaction)
        
        // Persist the purchased product ID
        IAPPersistence.savePurchasedState(for: transaction.payment.productIdentifier)

        // Add the purchased product ID to our fallback list of purchased product IDs
        if !haveFallbackPurchasedProductIdentifiers {
            fallbackPurchasedProductIdentifiers = Set<ProductId>()
        }
        
        guard !fallbackPurchasedProductIdentifiers!.contains(transaction.payment.productIdentifier) else { return }
        fallbackPurchasedProductIdentifiers!.insert(transaction.payment.productIdentifier)
        
        // Note that we do not present a confirmation alert to the user as StoreKit will have already done so
    }

    fileprivate func purchaseFailed(transaction: SKPaymentTransaction) {
        // The purchase failed. Don't allow the user access to the product

        defer {
            // The use of the defer block guarantees that no matter when or how the method exits, 
            // the code inside the defer block will be executed when the method goes out of scope
            // Always call SKPaymentQueue.default().finishTransaction() for a failure
            SKPaymentQueue.default().finishTransaction(transaction)
        }

        isPurchasing = false
        var iapHelperError: IAPPurchaseFailureInfo
        let identifier = transaction.payment.productIdentifier

        if let e = transaction.error as NSError? {

            if e.code == SKError.paymentCancelled.rawValue {
                iapHelperError = IAPPurchaseFailureInfo(productId: identifier, cancel: true, description: e.localizedDescription, error: e)
                sendNotification(notification: .purchaseCancelled, object: iapHelperError)

            } else {

                iapHelperError = IAPPurchaseFailureInfo(productId: identifier, cancel: false, description: e.localizedDescription, error: e)
                sendNotification(notification: .purchaseFailed, object: iapHelperError)
            }

        } else {

            iapHelperError = IAPPurchaseFailureInfo(productId: identifier, cancel: false, description: nil, error: nil)
            sendNotification(notification: .purchaseCancelled, object: iapHelperError)
        }

        if iapHelperError.wasCancelled { return }  // Cancellations aren't failures
    }

    fileprivate func purchaseDeferred(transaction: SKPaymentTransaction) {
        // The purchase is in the deferred state. This happens when a device has parental restrictions enabled such
        // that in-app purchases require authorization from a parent. Do not allow access to the product at this point
        // Apple recommeds that there be no spinners or blocking while in this state as it could be hours or days 
        // before the purchase is approved or declined.

        isPurchasing = false
        sendNotification(notification: .purchaseDeferred, object: transaction.payment.productIdentifier)

        // Do NOT call SKPaymentQueue.default().finishTransaction() for .deferred status
    }

    fileprivate func purchaseInProgress(transaction: SKPaymentTransaction) {
        // The product purchase transaction has started. Do not allow access to the product yet

        sendNotification(notification: .purchaseInProgress, object: transaction.payment.productIdentifier)

        // Do NOT call SKPaymentQueue.default().finishTransaction() for .purchasing status
    }
}

// MARK:- SKRequestDelegate

extension IAPHelper: SKRequestDelegate {

    /// Called when the app store provides us with a refreshed receipt.
    public func requestDidFinish(_ request: SKRequest) {
        receiptRequest = nil  // Destroy the request object

        // Re-process the refreshed receipt
        receipt = IAPReceipt()
        guard receipt.isReachable,
              receipt.load(),
              receipt.validateSigning(),
              receipt.read(),
              receipt.validate() else {
            
            refreshReceiptCompletion?(.cantRefreshReceipt)
            return
        }
        
        refreshReceiptCompletion?(.noError)
    }
}



