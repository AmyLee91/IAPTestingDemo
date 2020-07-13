//
//  IAPHelper+SKRequestDelegate.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 13/07/2020.
//

import UIKit
import StoreKit

extension IAPHelper: SKRequestDelegate {

    /// Called when the app store provides us with a refreshed receipt.
    /// - Parameter request: The SKRequest object used to make the request.
    public func requestDidFinish(_ request: SKRequest) {
        receiptRequest = nil  // Destroy the request object
        sendNotification(notification: .receiptRefreshPushedByAppStore)
        processReceipt(refresh: true)
    }
}
