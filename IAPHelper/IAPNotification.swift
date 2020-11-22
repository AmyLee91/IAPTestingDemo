//
//  IAPHelperNotification.swift
//  IAPHelper
//
//  Created by Russell Archer on 07/12/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import Foundation

/// Informational logging notifications issued by IAPHelper
public enum IAPNotification: Error, Equatable {
    
    case configurationCantFindInBundle
    case configurationCantReadData
    case configurationCantDecode
    case configurationNoProductIds
    case configurationLoadCompleted
    case configurationLoadFailed
    case configurationEmpty
    
    case purchaseProductUnavailable(productId: ProductId)
    case purchaseAbortPurchaseInProgress
    case purchaseInProgress(productId: ProductId)
    case purchaseCompleted(productId: ProductId)
    case purchaseFailed(productId: ProductId)
    case purchaseCancelled(productId: ProductId)
    case purchaseDeferred(productId: ProductId)
    case purchaseRestored(productId: ProductId)
    case purchaseRestoreFailed(productId: ProductId)
    case purchasedProductsLoadCompleted
    case purchasedProductsValidatedAgainstReceipt
    
    case receiptBadUrl
    case receiptMissing
    case receiptLoadCompleted
    case receiptLoadFailed
    case receiptValidateSigningFailed
    case receiptValidateSigningSuccess
    case receiptReadCompleted
    case receiptReadFailed
    case receiptValidationCompleted
    case receiptValidationFailed
    case receiptRefreshInitiated
    case receiptRefreshCompleted
    case receiptRefreshFailed
    case receiptProcessingSuccess
    case receiptProcessingFailed
    
    case requestProductsSuccess
    case requestProductsDidFinish
    case requestProductsFailed
    case requestProductsNoProducts
    case requestProductsInvalidProducts
    case requestReceiptRefreshSuccess
    case requestReceiptRefreshFailed
    
    case appStoreChanged
    case appStoreRevokedEntitlements(productId: ProductId)
    case appStoreNoProductInfo
    
    /// A short description of the notification.
    /// - Returns: Returns a short description of the notification.
    public func shortDescription() -> String {
        switch self {
            
        case .configurationCantFindInBundle:            return "Can't find the .storekit configuration file in the main bundle"
        case .configurationCantReadData:                return "Can't read in-app purchase data from .storekit configuration file"
        case .configurationCantDecode:                  return "Can't decode in-app purchase data in the .storekit configuration file"
        case .configurationNoProductIds:                return "No preconfigured ProductIds. They should be defined in the .storekit config file"
        case .configurationLoadCompleted:               return "Configuration load of .storekit file completed"
        case .configurationLoadFailed:                  return "Configuration load of .storekit file failed"
        case .configurationEmpty:                       return "Configuration does not contain any product definitions"
                
        case .purchaseProductUnavailable:               return "Product unavailable for purchase"
        case .purchaseAbortPurchaseInProgress:          return "Purchase aborted because another purchase is already in progress"
        case .purchaseInProgress:                       return "Purchase in progress"
        case .purchaseDeferred:                         return "Purchase in progress. Awaiting authorization"
        case .purchaseCompleted:                        return "Purchase completed"
        case .purchaseFailed:                           return "Purchase failed"
        case .purchaseCancelled:                        return "Purchase cancelled"
        case .purchaseRestored:                         return "Purchases restored"
        case .purchaseRestoreFailed:                    return "Purchase restore failed"
        case .purchasedProductsLoadCompleted:           return "Purchased products loaded"
        case .purchasedProductsValidatedAgainstReceipt: return "Purchased products validated against receipt"
            
        case .receiptBadUrl:                            return "Receipt URL is invalid or missing"
        case .receiptMissing:                           return "Receipt missing"
        case .receiptLoadCompleted:                     return "Receipt load completed"
        case .receiptLoadFailed:                        return "Receipt load failed"
        case .receiptValidateSigningFailed:             return "Receipt validation of signing failed"
        case .receiptValidateSigningSuccess:            return "Receipt validation of signing completed"
        case .receiptReadCompleted:                     return "Receipt read completed"
        case .receiptReadFailed:                        return "Receipt read failed"
        case .receiptValidationCompleted:               return "Receipt validation completed"
        case .receiptValidationFailed:                  return "Receipt validation failed"
        case .receiptRefreshInitiated:                  return "Receipt refresh initiated"
        case .receiptRefreshCompleted:                  return "Receipt refresh completed"
        case .receiptRefreshFailed:                     return "Receipt refresh failed"
        case .receiptProcessingSuccess:                 return "Receipt processing completed"
        case .receiptProcessingFailed:                  return "Receipt processing failed"
            
        case .requestProductsSuccess:                   return "Localized product info retrieved from App Store"
        case .requestProductsDidFinish:                 return "The request for products from the App Store completed"
        case .requestProductsFailed:                    return "The request for products from the App Store failed"
        case .requestProductsNoProducts:                return "The App Store returned an empty list of products"
        case .requestProductsInvalidProducts:           return "The App Store returned a list of invalid (unrecognized) products"
        case .requestReceiptRefreshSuccess:             return "The request for a receipt refresh completed"
        case .requestReceiptRefreshFailed:              return "The request for a receipt refresh failed"
            
        case .appStoreChanged:                          return "The App Store storefront has changed"
        case .appStoreRevokedEntitlements:              return "The App Store revoked user entitlements"
        case .appStoreNoProductInfo:                    return "No localized product information is available"
        }
    }
}

/// Success/failure notifications used with completion handlers
public enum IAPCompletion: Error, Equatable {
    
    case configurationCantFindInBundle
    case configurationCantReadData
    case configurationCantDecode
    case configurationNoProductIds
    case configurationLoadCompleted
    case configurationLoadFailed
    case configurationEmpty
    
    case purchaseProductUnavailable(productId: ProductId)
    case purchaseAbortPurchaseInProgress
    case purchaseInProgress(productId: ProductId)
    case purchaseCompleted(productId: ProductId)
    case purchaseFailed(productId: ProductId)
    case purchaseCancelled(productId: ProductId)
    case purchaseDeferred(productId: ProductId)
    case purchaseRestored(productId: ProductId)
    case purchaseRestoreFailed(productId: ProductId)
    case purchasedProductsLoadCompleted
    case purchasedProductsValidatedAgainstReceipt
    
    case receiptBadUrl
    case receiptMissing
    case receiptLoadCompleted
    case receiptLoadFailed
    case receiptValidateSigningFailed
    case receiptValidateSigningSuccess
    case receiptReadCompleted
    case receiptReadFailed
    case receiptValidationCompleted
    case receiptValidationFailed
    case receiptRefreshInitiated
    case receiptRefreshCompleted
    case receiptRefreshFailed
    case receiptProcessingSuccess
    case receiptProcessingFailed
    
    case requestProductsSuccess
    case requestProductsDidFinish
    case requestProductsFailed
    case requestProductsNoProducts
    case requestProductsInvalidProducts
    case requestReceiptRefreshSuccess
    case requestReceiptRefreshFailed
    
    case appStoreChanged
    case appStoreRevokedEntitlements(productId: ProductId)
    case appStoreNoProductInfo
    
    /// A short description of the notification.
    /// - Returns: Returns a short description of the notification.
    public func shortDescription() -> String {
        switch self {
            
        case .configurationCantFindInBundle:            return "Can't find the .storekit configuration file in the main bundle"
        case .configurationCantReadData:                return "Can't read in-app purchase data from .storekit configuration file"
        case .configurationCantDecode:                  return "Can't decode in-app purchase data in the .storekit configuration file"
        case .configurationNoProductIds:                return "No preconfigured ProductIds. They should be defined in the .storekit config file"
        case .configurationLoadCompleted:               return "Configuration load of .storekit file completed"
        case .configurationLoadFailed:                  return "Configuration load of .storekit file failed"
        case .configurationEmpty:                       return "Configuration does not contain any product definitions"
                
        case .purchaseProductUnavailable:               return "Product unavailable for purchase"
        case .purchaseAbortPurchaseInProgress:          return "Purchase aborted because another purchase is already in progress"
        case .purchaseInProgress:                       return "Purchase in progress"
        case .purchaseDeferred:                         return "Purchase in progress. Awaiting authorization"
        case .purchaseCompleted:                        return "Purchase completed"
        case .purchaseFailed:                           return "Purchase failed"
        case .purchaseCancelled:                        return "Purchase cancelled"
        case .purchaseRestored:                         return "Purchases restored"
        case .purchaseRestoreFailed:                    return "Purchase restore failed"
        case .purchasedProductsLoadCompleted:           return "Purchased products loaded"
        case .purchasedProductsValidatedAgainstReceipt: return "Purchased products validated against receipt"
            
        case .receiptBadUrl:                            return "Receipt URL is invalid or missing"
        case .receiptMissing:                           return "Receipt missing"
        case .receiptLoadCompleted:                     return "Receipt load completed"
        case .receiptLoadFailed:                        return "Receipt load failed"
        case .receiptValidateSigningFailed:             return "Receipt validation of signing failed"
        case .receiptValidateSigningSuccess:            return "Receipt validation of signing completed"
        case .receiptReadCompleted:                     return "Receipt read completed"
        case .receiptReadFailed:                        return "Receipt read failed"
        case .receiptValidationCompleted:               return "Receipt validation completed"
        case .receiptValidationFailed:                  return "Receipt validation failed"
        case .receiptRefreshInitiated:                  return "Receipt refresh initiated"
        case .receiptRefreshCompleted:                  return "Receipt refresh completed"
        case .receiptRefreshFailed:                     return "Receipt refresh failed"
        case .receiptProcessingSuccess:                 return "Receipt processing completed"
        case .receiptProcessingFailed:                  return "Receipt processing failed"
            
        case .requestProductsSuccess:                   return "Localized product info retrieved from App Store"
        case .requestProductsDidFinish:                 return "The request for products from the App Store completed"
        case .requestProductsFailed:                    return "The request for products from the App Store failed"
        case .requestProductsNoProducts:                return "The App Store returned an empty list of products"
        case .requestProductsInvalidProducts:           return "The App Store returned a list of invalid (unrecognized) products"
        case .requestReceiptRefreshSuccess:             return "The request for a receipt refresh completed"
        case .requestReceiptRefreshFailed:              return "The request for a receipt refresh failed"
            
        case .appStoreChanged:                          return "The App Store storefront has changed"
        case .appStoreRevokedEntitlements:              return "The App Store revoked user entitlements"
        case .appStoreNoProductInfo:                    return "No localized product information is available"
        }
    }
}
