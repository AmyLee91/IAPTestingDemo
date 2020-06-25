//
//  IAPHelperError.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 24/06/2020.
//

import Foundation

public struct IAPError {
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

