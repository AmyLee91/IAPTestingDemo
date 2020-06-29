//
//  IAPPurchaseFailureInfo.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 24/06/2020.
//

import Foundation

/// Error struct used by IAPHelper to provide additional information when a purchase does not succeed
public struct IAPPurchaseFailureInfo {
    public var productIdentifier: ProductId
    public var wasCancelled: Bool
    public var localizedDescription: String?
    public var error: NSError?

    init(productId: ProductId, cancel: Bool, description: String?, error: NSError?) {
        productIdentifier = productId
        wasCancelled = cancel
        localizedDescription = description
        self.error = error
    }
}


