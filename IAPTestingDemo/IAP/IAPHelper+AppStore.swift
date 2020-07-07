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
    /// - Parameter completion: Closure that will be called when the receipt has been refreshed.
    public func refreshReceipt(completion: @escaping (IAPError?) -> Void) {
        refreshReceiptCompletion = completion
        
        receiptRequest?.cancel()  // Cancel any existing pending requests
        receiptRequest = SKReceiptRefreshRequest()
        receiptRequest!.delegate = self
        receiptRequest!.start()  // Will notify through SKRequestDelegate requestDidFinish(_:)
        sendNotification(notification: .receiptRefreshInitiated)
    }
    
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
}
