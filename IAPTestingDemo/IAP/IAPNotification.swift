//
//  IAPHelperNotification.swift
//  Writerly
//
//  Created by Russell Archer on 07/12/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import Foundation

public enum IAPNotificaton {
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
    case receiptValid
    case receiptCannotBeValidated
    case requestProductsCompleted
    case requestProductsFailed

    public func key() -> String {
        switch self {
        case .purchaseStarted:              return "purchaseStarted"
        case .purchaseInProgress:           return "purchaseInProgress"
        case .purchaseDeferred:             return "purchaseDeferred"
        case .purchaseCompleted:            return "purchaseCompleted"
        case .purchaseFailed:               return "purchaseFailed"
        case .purchaseCancelled:            return "purchaseCancelled"
        case .purchaseRestored:             return "purchaseRestored"
        case .purchaseRestoreFailed:        return "purchaseRestoreFailed"
        case .purchaseValidationCompleted:  return "purchaseValidationCompleted"
        case .purchaseValidationFailed:     return "purchaseValidationFailed"
        case .receiptValid:                 return "receiptValid"
        case .receiptCannotBeValidated:     return "receiptCannotBeValidated"
        case .requestProductsCompleted:     return "requestProductsCompleted"
        case .requestProductsFailed:        return "requestProductsFailed"
        }
    }
    
    public func shortDescription() -> String {
        switch self {
        case .purchaseStarted:              return "Purchase Started"
        case .purchaseInProgress:           return "Purchase In Progress"
        case .purchaseDeferred:             return "Purchase Deferred"
        case .purchaseCompleted:            return "Purchase Completed"
        case .purchaseFailed:               return "Purchase Failed"
        case .purchaseCancelled:            return "Purchase Cancelled"
        case .purchaseRestored:             return "Purchase Restored"
        case .purchaseRestoreFailed:        return "Purchase Restore Failed"
        case .purchaseValidationCompleted:  return "Purchase Validation Completed"
        case .purchaseValidationFailed:     return "Purchase Validation Failed"
        case .receiptValid:                 return "Receipt Valid"
        case .receiptCannotBeValidated:     return "Receipt Cannot Be Validated"
        case .requestProductsCompleted:     return "Request Products Completed"
        case .requestProductsFailed:        return "Request Products Failed"
        }
    }

    public func description() -> String {
        switch self {
        case .purchaseStarted:              return "Purchase started"
        case .purchaseInProgress:           return "Purchase in progress"
        case .purchaseDeferred:             return "Purchase in progress. Awaiting authorization"
        case .purchaseCompleted:            return "Purchase completed"
        case .purchaseFailed:               return "Purchase failed"
        case .purchaseCancelled:            return "Purchase cancelled"
        case .purchaseRestored:             return "Purchases restored"
        case .purchaseRestoreFailed:        return "Purchase restore failed"
        case .purchaseValidationCompleted:  return "Purchases validated against App Store receipt"
        case .purchaseValidationFailed:     return "Purchases could not be validated against App Store receipt"
        case .receiptValid:                 return "App Store Receipt is valid"
        case .receiptCannotBeValidated:     return "App Store Receipt cannot be validated at this time"
        case .requestProductsCompleted:     return "Products retrieved from App Store"
        case .requestProductsFailed:        return "Unable to retrieve products from App Store"
        }
    }

    public static func keys() -> [String] {
        return ["purchaseStarted",
                "purchaseInProgress",
                "purchaseDeferred",
                "purchaseCompleted",
                "purchaseFailed",
                "purchaseCancelled",
                "purchaseRestored",
                "purchaseRestoreFailed",
                "purchaseValidationCompleted",
                "purchaseValidationFailed",
                "receiptValid",
                "receiptCannotBeValidated",
                "requestProductsCompleted",
                "requestProductsFailed"]
    }
}
