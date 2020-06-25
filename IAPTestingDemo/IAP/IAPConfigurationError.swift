//
//  IAPConfigurationError.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

public enum IAPConfigurationError: Error {
    case noError
    case cantFindInBundle
    case cantReadData
    case cantDecode
    case receiptUrlMissing
    case receiptMissing
    case cantValidateReceipt
    
    public func shortDescription() -> String {
        switch self {
            case .noError:              return ""
            case .cantFindInBundle:     return "Can't find the .storekit configuration file in the main bundle."
            case .cantReadData:         return "Can't read in-app purchase data from .storekit configuration file."
            case .cantDecode:           return "Can't decode in-app purchase data in the .storekit configuration file."
            case .receiptUrlMissing:    return "The App Store receipt URL is missing."
            case .receiptMissing:       return "The App Store receipt cannot be located in the main bundle."
            case .cantValidateReceipt:  return "Can't validate App Store receipt."
        }
    }
}

