//
//  IAPHelper.swift
//  Writerly
//
//  Created by Russell Archer on 16/10/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import UIKit
import StoreKit

public typealias ProductId = String

/// IAPHelper coordinates in-app purchases. Make sure to initiate IAPHelper early in the app's lifecycle so that
/// notifications from the App Store are not missed. For example, reference `IAPHelper.shared` in
/// `application(_:didFinishLaunchingWithOptions:)` in AppDelegate.
public class IAPHelper: NSObject  {
    
    // MARK:- Public Properties
    
    /// Singleton access. Use IAPHelper.shared to access all IAPHelper properties and methods.
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
    
    // MARK:- Internal Properties

    internal var receipt: IAPReceipt!                                     // Represents the app store receipt located in the main bundle
    internal var productsRequest: SKProductsRequest?                      // Used to request product info async from the App Store
    internal var receiptRequest: SKRequest?                               // Used to request a receipt refresh async from the App Store
    internal var refreshReceiptCompletion: ((IAPError?) -> Void)? = nil   // Used when requesting a refreshed receipt from the app store
    internal var requestProductsCompletion: ((IAPError?) -> Void)? = nil  // Used when requesting products from the app store
    
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
        // notifications when payments are successful, fail, are restored, etc.
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

    // MARK:- Public Helpers
    
    /// Helper to enable an object to observe an IAP-related notifications.
    /// - Parameters:
    ///   - notifications: Array of IAPNotification.
    ///   - observer: The observer that wishes to receive notifications.
    ///   - selector: The method which will receive notifications.
    public func addObserverForNotifications(notifications: [IAPNotificaton], observer: Any, selector: Selector) {
        for notification in notifications {
            NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: notification.key()), object: nil)
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
    
    /// Returns true if the product identified by the ProductId has been purchased.
    /// There are two strategies we use to determine if a product has been successfully purchased:
    ///
    ///   1. We validate the App Store-issued Receipt, which is stored in our main bundle. This receipt
    ///      is updated and reissued as necessary (for example, when there's a purchase) by the App Store.
    ///      The data in the receipt gives a list of purchased products.
    ///
    ///   2. We keep a 'fallback' list of ProductIDs for purchased products. This list is persisted to
    ///      UserDefaults. We use this list in case we can't use method 1. above. This can happen when
    ///      the receipt is missing, or hasn't yet been issued (i.e. the user hasn't purchased anything).
    ///      The fallback list is also useful when we can't validate the receipt and can't request a
    ///      new receipt from the App Store becuase of network connectivity issues, etc.
    ///
    /// When we validate the receipt we compare the fallback list of purchases with the more reliable
    /// data from the receipt. If they disagree we re-write the list using info from the receipt.
    /// - Parameter id: The ProductId for the product.
    /// - Returns: Returns true if the product has previously been purchased, false otherwise.
    public func isProductPurchased(id: ProductId) -> Bool {
        guard isAppStoreProductInfoAvailable else { return false }

        return fallbackPurchasedProductIdentifiers.contains(id)
    }
    
    /// Get a localized price for a product.
    /// - Parameter product: SKProduct for which you want the local price.
    /// - Returns: Returns a localized price String for a product.
    public class func getLocalizedPriceFor(product: SKProduct) -> String? {
        let priceFormatter = NumberFormatter()
        priceFormatter.formatterBehavior = .behavior10_4
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        return priceFormatter.string(from: product.price)
    }
    
    // MARK:- Internal Helpers
    
    internal func sendNotification(notification: IAPNotificaton, object: Any? = nil) {
        DispatchQueue.main.async { NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification.key()), object: object) }
        IAPLog.event(event: notification)
    }
    
    internal func createValidatedFallbackProductIds() {
        if !receipt.validateFallbackProductIds(fallbackPids: fallbackPurchasedProductIdentifiers) {
            IAPPersistence.resetPurchasedProductIds(from: fallbackPurchasedProductIdentifiers, to: receipt.validatedPurchasedProductIdentifiers)
            fallbackPurchasedProductIdentifiers = receipt.validatedPurchasedProductIdentifiers
            sendNotification(notification: .receiptFallbackReset)
        }
        
        sendNotification(notification: .receiptFallbackValidationCompleted)
        purchasesValid = true
    }
}

// MARK:- SKRequestDelegate

extension IAPHelper: SKRequestDelegate {

    /// Called when the app store provides us with a refreshed receipt.
    /// - Parameter request: The SKRequest object used to make the request.
    public func requestDidFinish(_ request: SKRequest) {
        receiptRequest = nil  // Destroy the request object
        sendNotification(notification: .receiptRefreshPushedByAppStore)
        processReceipt(refresh: true)
    }
}

// MARK:- IAPReceiptDelegate

extension IAPHelper: IAPReceiptDelegate {
    
    /// Make a request to send an IAP-related notification.
    /// - Parameter notification: The required notification.
    public func requestSendNotification(notification: IAPNotificaton) {
        sendNotification(notification: notification)
    }
}


