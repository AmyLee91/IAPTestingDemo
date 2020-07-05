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

/// Helper that coordinates in-app purchases. Make sure to initiate IAPHelper early in the app's lifecycle so that
/// notifications from the App Store are not missed. For example, reference `IAPHelper.shared` in
/// `application(_:didFinishLaunchingWithOptions:)` in AppDelegate.
public class IAPHelper: NSObject  {
    
    // MARK:- Public Properties
    
    /// Singleton access.
    public static let shared: IAPHelper = IAPHelper()

    /// True if the fallback and receipt purchases agree.
    public var purchasesValid       = false
    
    /// True if a purchase is in progress (excluding a deferred).
    public var isPurchasing         = false
    
    /// True if we've added ourselves to the SKPaymentQueue.
    public var addedToPaymentQueue  = false

    /// List of products retrieved from the App Store and available for purchase.
    public var products: [SKProduct]?
    
    /// List of ProductIds that are read from the .storekit configuration file.
    public var configuredProductIdentifiers: Set<ProductId>?
    
    /// True if we have a list of ProductIds read from the .storekit configuration file. See configuredProductIdentifiers.
    public var haveConfiguredProductIdentifiers: Bool {
        guard configuredProductIdentifiers != nil else { return false }
        return configuredProductIdentifiers!.count > 0 ? true : false
    }
    
    /// This property is set automatically when IAPHelper is initialized and contains the set of
    /// all products purchased by the user. The collection is not persisted but is rebuilt from the
    /// product identifiers of purchased products stored individually in user defaults (see IAPPersistence).
    /// This is a fall-back collection of purchases designed to allow the user access to purchases
    /// in the event that the app receipt is missing and we can't contact the App Store to refresh it.
    /// THis set will be empty if the user hasn't yet purchased any iap products.
    public var fallbackPurchasedProductIdentifiers = Set<ProductId>()
    
    /// True if app store product info has been retrieved via requestProducts().
    public var isAppStoreProductInfoAvailable: Bool {
        guard products != nil else { return false }
        guard products!.count > 0 else { return false }
        return true
    }
    
    // MARK:- Private Properties

    private var receipt: IAPReceipt!                                     // Represents the app store receipt located in the main bundle
    private var productsRequest: SKProductsRequest?                      // Used to request product info async from the App Store
    private var receiptRequest: SKRequest?                               // Used to request a receipt refresh async from the App Store
    private var refreshReceiptCompletion: ((IAPError?) -> Void)? = nil   // Used when requesting a refreshed receipt from the app store
    private var requestProductsCompletion: ((IAPError?) -> Void)? = nil  // Used when requesting products from the app store
    
    // MARK:- Initialization
    
    // Private initializer prevents more than a single instance of this class being created.
    // See the public static 'shared' property.
    private override init() {
        super.init()
        setup()
    }
    
    // MARK:- Configuration
    
    internal func setup() {
        addToPaymentQueue()
        readConfigFile()
        loadFallbackProductIds()
        processReceipt()
    }
    
    internal func processReceipt(refresh: Bool = false) {
        receipt = IAPReceipt()
        receipt.delegate = self
        
        // If any of the following fail then this should be considered a non-fatal error.
        // A new receipt can be requested from the App Store if required (see refreshReceipt(completion:)).
        // However, we don't do this automatically because it will cause the user to be prompted
        // for their App Store credentials (not a good UX for a first time user).
        guard receipt.isReachable,
              receipt.load(),
              receipt.validateSigning(),
              receipt.read(),
              receipt.validate() else {
            
            if refresh {
                sendNotification(notification: .receiptRefreshFailed)
                refreshReceiptCompletion?(.cantRefreshReceipt)
            }
            
            return
        }
        
        createValidatedFallbackProductIds()
        
        if refresh {
            sendNotification(notification: .receiptRefreshCompleted)
            refreshReceiptCompletion?(.noError)
        }
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
        // Read our configuration file that contains the list of ProductIds that are available on the App Store.
        // If the data can't be read then it isn't a critcial error as we can request the info from the App Store
        // as required.
        configuredProductIdentifiers = nil
        let result = IAPConfiguration.read(filename: IAPConstants.File(), ext: IAPConstants.FileExt())
        switch result {
            case .failure(let error):
                IAPLog.event(error: error)
                sendNotification(notification: .configurationLoadFailed)
                
            case .success(let configuration):
                guard let configuredProducts = configuration.products, configuredProducts.count > 0 else {
                    sendNotification(notification: .configurationEmpty)
                    return
                }
                
                configuredProductIdentifiers = Set<ProductId>(configuredProducts.compactMap { product in product.productID })
                sendNotification(notification: .configurationLoadCompleted)
        }
    }
    
    internal func loadFallbackProductIds() {
        // Load our fallback list of purchased ProductIds
        guard haveConfiguredProductIdentifiers else {
            sendNotification(notification: .receiptFallbackLoadCompleted)
            return
        }
        
        fallbackPurchasedProductIdentifiers = IAPPersistence.loadPurchasedProductIds(for: configuredProductIdentifiers!)        
        sendNotification(notification: .receiptFallbackLoadCompleted)
    }
    
    // MARK:- Receipt
    
    /// Should be used only when the receipt is not present at the appStoreReceiptURL or when
    /// it cannot be successfully validated. The app store is requested to provide a new receipt,
    /// which will result in the user being asked to provide their App Store credentials.
    /// - Parameter completion: Closure that will be called when the receipt has been refreshed.
    public func refreshReceipt(completion: @escaping (IAPError?) -> Void) {
        refreshReceiptCompletion = completion
        
        receiptRequest?.cancel()  // Cancel any existing pending requests
        receiptRequest = SKReceiptRefreshRequest()
        receiptRequest!.delegate = self
        receiptRequest!.start()  // Will notify through SKRequestDelegate requestDidFinish(_:)
        sendNotification(notification: .receiptRefreshInitiated)
    }
    
    // MARK:- App Store
    
    /// Request from the App Store the collection of products that we've configured for sale in App Store Connect.
    /// Note that requesting product info will cause the App Store to provide a refreshed receipt.
    /// - Parameter completion: A closure that will be called when the results are returned from the App Store.
    public func requestProductsFromAppStore(completion: @escaping (IAPError?) -> Void) {
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
        // productsRequest(_:didReceive:) then it makes a call to validateReceiptAndGetProductsIds().
        productsRequest = SKProductsRequest(productIdentifiers: configuredProductIdentifiers!)
        productsRequest!.delegate = self
        productsRequest!.start()
        
        sendNotification(notification: .requestProductsInitiated)
    }

    // MARK:- Public Helpers
    
    /// Helper to enable an object to observe an IAP-related notifications.
    /// - Parameters:
    ///   - notifications: Array of IAPNotification.
    ///   - observer: The observer that wishes to receive notifications.
    ///   - selector: The method which will receive notifications.
    public func addObserverForNotifications(notifications: [IAPNotificaton], observer: Any, selector: Selector) {
        for notification in notifications {
            NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: notification.key()), object: nil)
            //addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: notification.key(), object: nil))
        }
    }

    /// Helper to enable an object to remove itself as an observer of an IAP-related notifications.
    /// - Parameters:
    ///   - notifications: Array of IAPNotification.
    ///   - observer: The observer that wishes to no longer receive notifications.
    public func removeObserverForNotifications(notifications: [IAPNotificaton], observer: Any) {
        for notification in notifications {
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: notification.key()), object: nil)
        }
    }

    /// Returns an SKProduct given a ProductId. Product info is only available if isStoreProductInfoAvailable is true
    /// - Parameter id: The ProductId for the product.
    /// - Returns: Returns an SKProduct object containing localized information about the product.
    public func getStoreProductFrom(id: ProductId) -> SKProduct? {
        guard isAppStoreProductInfoAvailable else { return nil }
        for p in products! { if p.productIdentifier == id { return p } }
        return nil
    }
    
    /// Returns true if the product identified by the ProductId has been purchased
    /// - Parameter id: The ProductId for the product.
    /// - Returns: Returns true if the product has previously been purchased, false otherwise.
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

        return fallbackPurchasedProductIdentifiers.contains(id)
    }
    
    // MARK:- Private Helpers
    
    private func sendNotification(notification: IAPNotificaton, object: Any? = nil) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification.key()), object: object)
        IAPLog.event(event: notification)
    }
    
    private func createValidatedFallbackProductIds() {
        if !receipt.validateFallbackProductIds(fallbackPids: fallbackPurchasedProductIdentifiers) {
            IAPPersistence.resetPurchasedProductIds(from: fallbackPurchasedProductIdentifiers, to: receipt.validatedPurchasedProductIdentifiers)
            fallbackPurchasedProductIdentifiers = receipt.validatedPurchasedProductIdentifiers
            sendNotification(notification: .receiptFallbackReset)
        }
        
        sendNotification(notification: .receiptFallbackValidationCompleted)
        purchasesValid = true
    }
}

// MARK:- StoreKit

public extension IAPHelper {

    internal func buyProduct(_ product: SKProduct) {
        if isPurchasing { return }  // Don't allow another purchase to start until the current one completes

        let payment = SKPayment(product: product)  // Wrap the product in an SKPayment object
        isPurchasing = true

        // Add the payment to the default payment queue. StoreKit will present the required UI to the user
        // and start processing the payment. When that transaction is complete or if a failure occurs, the 
        // payment queue sends the SKPaymentTransaction object that encapsulates the request to all 
        // transaction observers. See our paymentQueue(_:updatedTransactions) for how these events get handled
        SKPaymentQueue.default().add(payment)
    }

    internal func restorePurchases() {
        // Ask StoreKit to restore any previous purchases that are missing from this device
        // The user will be asked to authenticate. Will result in zero or more transactions
        // to be received from the payment queue. See the SKPaymentTransactionObserver delegate below
        
        if isPurchasing { return }  // Don't allow restore process to start until the current purchase completes

        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    internal class func canMakePayments() -> Bool {
        // The Apple ID of some users (e.g. children) may not have permission to make purchases from the app store
        // Returns true if the user is allowed to authorize payment, false if they do not have permission
        return SKPaymentQueue.canMakePayments()
    }
}

// MARK:- SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    
    /// Receives a list of localized product info from the App Store.
    /// - Parameters:
    ///   - request: The request object.
    ///   - response: The response from the App Store.
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
    
    /// Called by the App Store if a request fails.
    /// - Parameters:
    ///   - request: The request object.
    ///   - error: The error returned by the App Store.
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        sendNotification(notification: .requestProductsFailed)
        productsRequest = nil
    }
}

// MARK:- SKPaymentTransactionObserver
/*
 
 // Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
 func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
 
 // Sent when transactions are removed from the queue (via finishTransaction:).
 func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction])

 // Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
 func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error)

 // Sent when all transactions from the user's purchase history have successfully been added back to the queue.
 func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue)

 // Sent when the download state has changed.
 func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload])

 // Sent when a user initiates an IAP buy from the App Store
 @available(iOS 11.0, *)
 optional func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool
 
 // YES: Tells the observer that the storefront for the payment queue has changed.
 @available(iOS 13.0, *)
 func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue)
 
 // YES: Sent when entitlements for a user have changed and access to the specified IAPs has been revoked.
 @available(iOS 14.0, *)
 func paymentQueue(_ queue: SKPaymentQueue, didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String])
 
 */
extension IAPHelper: SKPaymentTransactionObserver {
    
    /// This delegate allows us to receive notifications from the App Store when payments are successful, fail or are restored.
    /// - Parameters:
    ///   - queue: The payment queue object.
    ///   - transactions: Transaction information.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:   purchaseInProgress(transaction: transaction)
            case .purchased:    purchaseCompleted(transaction: transaction)
            case .failed:       purchaseFailed(transaction: transaction)
            case .restored:     purchaseCompleted(transaction: transaction, restore: true)
            case .deferred:     purchaseDeferred(transaction: transaction)
            default:            return
            }
        }
    }
    
    /// New optional delegate method for iOS 11. Tells the observer that a user initiated an in-app purchase from the App Store
    /// (rather than via the app itself).
    /// - Parameters:
    ///   - queue: Payment queue object.
    ///   - payment: Payment info.
    ///   - product: The product purchased.
    /// - Returns: Return true to continue the transaction (will result in normal processing via paymentQueue(_:updatedTransactions:).
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
        if isProductPurchased(id: product.productIdentifier) {
            if #available(iOS 13, *) {
                IAPUtils.showMessage(msg: "You have already purchased \(product.localizedTitle)", title: "Purchase Cancelled")
            }
            return false  // Tell the store not to proceed with purchase
        }

        return true  // Return true to continue the transaction (will result in normal processing via paymentQueue(_:updatedTransactions:)
    }

    public func purchaseCompleted(transaction: SKPaymentTransaction, restore: Bool = false) {
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
        guard !fallbackPurchasedProductIdentifiers.contains(transaction.payment.productIdentifier) else { return }
        fallbackPurchasedProductIdentifiers.insert(transaction.payment.productIdentifier)
        
        // Note that we do not present a confirmation alert to the user as StoreKit will have already done so
    }

    public func purchaseFailed(transaction: SKPaymentTransaction) {
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

    public func purchaseDeferred(transaction: SKPaymentTransaction) {
        // The purchase is in the deferred state. This happens when a device has parental restrictions enabled such
        // that in-app purchases require authorization from a parent. Do not allow access to the product at this point
        // Apple recommeds that there be no spinners or blocking while in this state as it could be hours or days 
        // before the purchase is approved or declined.

        isPurchasing = false
        sendNotification(notification: .purchaseDeferred, object: transaction.payment.productIdentifier)

        // Do NOT call SKPaymentQueue.default().finishTransaction() for .deferred status
    }

    public func purchaseInProgress(transaction: SKPaymentTransaction) {
        // The product purchase transaction has started. Do not allow access to the product yet

        sendNotification(notification: .purchaseInProgress, object: transaction.payment.productIdentifier)

        // Do NOT call SKPaymentQueue.default().finishTransaction() for .purchasing status
    }
    
    @available(iOS 13.0, *)
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        
    }
    
    /// Sent when entitlements for a user have changed and access to the specified IAPs has been revoked.
    /// - Parameters:
    ///   - queue: Payment queue.
    ///   - productIdentifiers: ProductId which should have user access revoked.
    @available(iOS 14.0, *)
    public func paymentQueue(_ queue: SKPaymentQueue, didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        // TODO
    }
}

// MARK:- SKRequestDelegate

extension IAPHelper: SKRequestDelegate {

    /// Called when the app store provides us with a refreshed receipt.
    public func requestDidFinish(_ request: SKRequest) {
        receiptRequest = nil  // Destroy the request object
        sendNotification(notification: .receiptRefreshPushedByAppStore)
        processReceipt(refresh: true)
    }
}

// MARK:- IAPReceiptDelegate

extension IAPHelper: IAPReceiptDelegate {
    public func requestSendNotification(notification: IAPNotificaton) {
        sendNotification(notification: notification)
    }
}
