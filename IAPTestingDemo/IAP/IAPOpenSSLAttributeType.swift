//
//  OpenSSLAttributeType.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 03/07/2020.
//

import Foundation

public enum IAPOpenSSLAttributeType: Int {

    case BundleIdentifier       = 2
    case BudleVersion           = 3
    case OpaqueValue            = 4
    case ComputedGuid           = 5
    case ReceiptCreationDate    = 12
    case IAPReceipt             = 17
    case OriginalAppVersion     = 19
    case ExpirationDate         = 21
}

