//
//  IAPHelperNotification.swift
//  Writerly
//
//  Created by Russell Archer on 07/12/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import Foundation

/// Notifications issued by IAPHelper
public enum IAPNotification: Error {
    case configurationCantFindInBundle
    case configurationCantReadData
    case configurationCantDecode
    case configurationNoProductIds
    case configurationLoadCompleted
    case configurationLoadFailed
    case configurationEmpty
    
    case purchaseStarted
    case purchaseInProgress(productId: ProductId)
    case purchaseDeferred(productId: ProductId)
    case purchaseCompleted(productId: ProductId)
    case purchaseFailed(productId: ProductId)
    case purchaseCancelled(productId: ProductId)
    case purchaseRestored(productId: ProductId)
    case purchaseRestoreFailed(productId: ProductId)
    case purchaseValidationCompleted
    case purchaseValidationFailed
    
    case receiptFallbackLoadCompleted
    case receiptFallbackValidationFailed
    case receiptFallbackValidationCompleted
    case receiptFallbackReset
    case receiptMissing
    case receiptUrlMissing
    case receiptLoadCompleted
    case receiptLoadFailed
    case receiptValidateSigningCompleted
    case receiptValidateSigningFailed
    case receiptReadCompleted
    case receiptReadFailed
    case receiptValidationCompleted
    case receiptValidationFailed
    case receiptRefreshInitiated
    case receiptRefreshPushedByAppStore
    case receiptRefreshCompleted
    case receiptRefreshFailed
    
    case requestProductsInitiated
    case requestProductsCompleted
    case requestProductsFailed
    case requestProductsNoProducts
    
    case appStoreChanged
    case appStoreRevokedEntitlements(productId: ProductId)
    
    public func shortDescription() -> String {
        switch self {
            
        case .configurationCantFindInBundle:        return "Can't find the .storekit configuration file in the main bundle"
        case .configurationCantReadData:            return "Can't read in-app purchase data from .storekit configuration file"
        case .configurationCantDecode:              return "Can't decode in-app purchase data in the .storekit configuration file"
        case .configurationNoProductIds:            return "No preconfigured ProductIds. They should be defined in the .storekit config file"
        case .configurationLoadCompleted:           return "Configuration load of .storekit file completed"
        case .configurationLoadFailed:              return "Configuration load of .storekit file failed"
        case .configurationEmpty:                   return "Configuration does not contain any product definitions"
            
        case .purchaseStarted:                      return "Purchase started"
        case .purchaseInProgress:                   return "Purchase in progress"
        case .purchaseDeferred:                     return "Purchase in progress. Awaiting authorization"
        case .purchaseCompleted:                    return "Purchase completed"
        case .purchaseFailed:                       return "Purchase failed"
        case .purchaseCancelled:                    return "Purchase cancelled"
        case .purchaseRestored:                     return "Purchases restored"
        case .purchaseRestoreFailed:                return "Purchase restore failed"
        case .purchaseValidationCompleted:          return "Purchases validated against App Store receipt"
        case .purchaseValidationFailed:             return "Purchases could not be validated against App Store receipt"
            
            
        case .receiptFallbackLoadCompleted:         return "Receipt fallback list load completed"
        case .receiptFallbackValidationFailed:      return "Receipt fallback list validation failed"
        case .receiptFallbackValidationCompleted:   return "Receipt fallback validation completed"
        case .receiptFallbackReset:                 return "Receipt fallback list reset"
        case .receiptMissing:                       return "Receipt missing"
        case .receiptUrlMissing:                    return "The App Store receipt URL is missing"
        case .receiptLoadCompleted:                 return "Receipt load completed"
        case .receiptLoadFailed:                    return "Receipt load failed"
        case .receiptValidateSigningCompleted:      return "Receipt validation of signing completed"
        case .receiptValidateSigningFailed:         return "Receipt validation of signing failed"
        case .receiptReadCompleted:                 return "Receipt read completed"
        case .receiptReadFailed:                    return "Receipt read failed"
        case .receiptValidationCompleted:           return "Receipt validation completed"
        case .receiptValidationFailed:              return "Receipt validation failed"
        case .receiptRefreshInitiated:              return "Receipt refresh initiated"
        case .receiptRefreshPushedByAppStore:       return "Receipt refresh was pushed to us by the App Store"
        case .receiptRefreshCompleted:              return "Receipt refresh completed"
        case .receiptRefreshFailed:                 return "Receipt refresh failed"
            
        case .requestProductsInitiated:             return "Requested product information from the App Store"
        case .requestProductsCompleted:             return "Products retrieved from App Store"
        case .requestProductsFailed:                return "Unable to retrieve products from App Store"
        case .requestProductsNoProducts:            return "The App Store returned an empty list of products"

        case .appStoreChanged:                      return "The App Store storefront has changed"
        case .appStoreRevokedEntitlements:          return "The App Store revoked user entitlements"
        }
    }
}
