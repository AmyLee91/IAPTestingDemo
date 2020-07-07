//
//  IAPHelper+SKProductsRequestDelegate.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 06/07/2020.
//

import UIKit
import StoreKit

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
