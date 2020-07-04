//
//  IAPHelperNotification.swift
//  Writerly
//
//  Created by Russell Archer on 07/12/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import Foundation

/// Notifications issued by IAPHelper
public enum IAPNotificaton {
    case configurationLoadCompleted
    case configurationLoadFailed
    case configurationEmpty
    case purchaseStarted
    case purchaseInProgress
    case purchaseDeferred
    case purchaseCompleted
    case purchaseFailed
    case purchaseCancelled
    case purchaseRestored
    case purchaseRestoreFailed
    case purchaseValidationCompleted
    case purchaseValidationFailed
    case receiptFallbackLoadCompleted
    case receiptFallbackValidationFailed
    case receiptFallbackValidationCompleted
    case receiptFallbackReset
    case receiptMissing
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

    public func key() -> String {
        switch self {
        case .configurationLoadCompleted:           return "configurationLoadCompleted"
        case .configurationLoadFailed:              return "configurationLoadFailed"
        case .configurationEmpty:                   return "configurationEmpty"
        case .purchaseStarted:                      return "purchaseStarted"
        case .purchaseInProgress:                   return "purchaseInProgress"
        case .purchaseDeferred:                     return "purchaseDeferred"
        case .purchaseCompleted:                    return "purchaseCompleted"
        case .purchaseFailed:                       return "purchaseFailed"
        case .purchaseCancelled:                    return "purchaseCancelled"
        case .purchaseRestored:                     return "purchaseRestored"
        case .purchaseRestoreFailed:                return "purchaseRestoreFailed"
        case .purchaseValidationCompleted:          return "purchaseValidationCompleted"
        case .purchaseValidationFailed:             return "purchaseValidationFailed"
        case .receiptFallbackLoadCompleted:         return "receiptFallbackLoadCompleted"
        case .receiptFallbackValidationFailed:      return "receiptFallbackValidationFailed"
        case .receiptFallbackValidationCompleted:   return "receiptFallbackValidationCompleted"
        case .receiptFallbackReset:                 return "receiptFallbackReset"
        case .receiptMissing:                       return "receiptMissing"
        case .receiptLoadCompleted:                 return "receiptLoadCompleted"
        case .receiptLoadFailed:                    return "receiptLoadFailed"
        case .receiptValidateSigningCompleted:      return "receiptValidateSigningCompleted"
        case .receiptValidateSigningFailed:         return "receiptValidateSigningFailed"
        case .receiptReadCompleted:                 return "receiptReadCompleted"
        case .receiptReadFailed:                    return "receiptReadFailed"
        case .receiptValidationCompleted:           return "receiptValidationCompleted"
        case .receiptValidationFailed:              return "receiptValidationFailed"
        case .receiptRefreshInitiated:              return "receiptRefreshInitiated"
        case .receiptRefreshPushedByAppStore:       return "receiptRefreshPushedByAppStore"
        case .receiptRefreshCompleted:              return "receiptRefreshCompleted"
        case .receiptRefreshFailed:                 return "receiptRefreshFailed"
        case .requestProductsInitiated:             return "requestProductsInitiated"
        case .requestProductsCompleted:             return "requestProductsCompleted"
        case .requestProductsFailed:                return "requestProductsFailed"
        }
    }
    
    public func shortDescription() -> String {
        switch self {
        case .configurationLoadCompleted:           return "Configuration Load Completed"
        case .configurationLoadFailed:              return "Configuration Load Failed"
        case .configurationEmpty:                   return "Configuration Empty"
        case .purchaseStarted:                      return "Purchase Started"
        case .purchaseInProgress:                   return "Purchase In Progress"
        case .purchaseDeferred:                     return "Purchase Deferred"
        case .purchaseCompleted:                    return "Purchase Completed"
        case .purchaseFailed:                       return "Purchase Failed"
        case .purchaseCancelled:                    return "Purchase Cancelled"
        case .purchaseRestored:                     return "Purchase Restored"
        case .purchaseRestoreFailed:                return "Purchase Restore Failed"
        case .purchaseValidationCompleted:          return "Purchase Validation Completed"
        case .purchaseValidationFailed:             return "Purchase Validation Failed"
        case .receiptFallbackLoadCompleted:         return "Receipt Fallback Load Completed"
        case .receiptFallbackValidationFailed:      return "Receipt Fallback Validation Failed"
        case .receiptFallbackValidationCompleted:   return "Receipt Fallback Validation Completed"
        case .receiptFallbackReset:                 return "Receipt Fallback Reset"
        case .receiptMissing:                       return "Receipt Missing"
        case .receiptLoadCompleted:                 return "Receipt Load Completed"
        case .receiptLoadFailed:                    return "Receipt Load Failed"
        case .receiptValidateSigningCompleted:      return "Receipt Validate Signing Completed"
        case .receiptValidateSigningFailed:         return "Receipt Validate Signing Failed"
        case .receiptReadCompleted:                 return "Receipt Read Completed"
        case .receiptReadFailed:                    return "Receipt Read Failed"
        case .receiptValidationCompleted:           return "Receipt Validation Completed"
        case .receiptValidationFailed:              return "Receipt Validation Failed"
        case .receiptRefreshInitiated:              return "Receipt Refresh Initiated"
        case .receiptRefreshPushedByAppStore:       return "Receipt Refresh Pushed By App Store"
        case .receiptRefreshCompleted:              return "Receipt Refresh Completed"
        case .receiptRefreshFailed:                 return "Receipt Refresh Failed"
        case .requestProductsInitiated:             return "Request Products Initiated"
        case .requestProductsCompleted:             return "Request Products Completed"
        case .requestProductsFailed:                return "Request Products Failed"
        }
    }

    public func description() -> String {
        switch self {
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
        }
    }
}
