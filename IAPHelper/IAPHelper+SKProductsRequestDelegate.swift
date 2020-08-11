//
//  IAPHelper+SKProductsRequestDelegate.swift
//  IAPHelper
//
//  Created by Russell Archer on 06/07/2020.
//

import UIKit
import StoreKit

extension IAPHelper: SKProductsRequestDelegate {
    
    /// Receives a list of localized product info from the App Store.
    /// - Parameters:
    ///   - request:    The request object.
    ///   - response:   The response from the App Store.
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count == 0 {
            self.sendNotification(notification: .requestProductsNoProducts)
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsNoProducts) }
            return
        }

        // Update our [SKProduct] set of all available products
        products = response.products
        
        productsRequest = nil  // Destroy the request object
        DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsCompleted) }
        
        // Send a notification to let observers know we have an updated set of products.
        sendNotification(notification: .requestProductsCompleted)
    }
    
    /// Called by the App Store if a request fails.
    /// - Parameters:
    ///   - request:    The request object.
    ///   - error:      The error returned by the App Store.
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequest = nil
        DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsFailed) }
        sendNotification(notification: .requestProductsFailed)
    }
}

