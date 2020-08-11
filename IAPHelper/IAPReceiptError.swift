//
//  IAPReceiptError.swift
//  IAPHelper
//
//  Created by Russell Archer on 03/07/2020.
//

import Foundation

/// IAPReceiptError used to provide detailed information regarding receipt processing errors.
public enum IAPReceiptError: Error {
    case noError
    case missing
    case badUrl
    case badFormat
    case badPKCS7Signature
    case badPKCS7Type
    case noData
    case invalidAppleRootCertificate
    case failedAppleSignature
    case unexpectedASN1Type
    case missingComponent
    case unknownFailure
    case invalidBundleIdentifier
    case invalidVersionIdentifier
    case invalidHash
    case expired
    
    /// A short description of the error.
    /// - Returns: Returns a short description of the error.
    public func shortDescription() -> String {
        switch self {
            case .noError:                      return ""
            case .missing:                      return "Receipt missing"
            case .badUrl:                       return "Receipt cannot be reached by provided URL"
            case .badFormat:                    return "Receipt has bad format"
            case .badPKCS7Signature:            return "Receipt has bad PKCS7 signature"
            case .badPKCS7Type:                 return "Receipt has bad PKCS7 type"
            case .noData:                       return "Receipt has no data"
            case .invalidAppleRootCertificate:  return "Receipt has an invalid Apple root certificate"
            case .failedAppleSignature:         return "Receipt failed to validate Apple signature"
            case .unexpectedASN1Type:           return "Receipt has unexpected ASN1 type"
            case .missingComponent:             return "Receipt has a missing component"
            case .unknownFailure:               return "Receipt has an unknown failure"
            case .invalidBundleIdentifier:      return "Receipt has an invalid bundle identifier"
            case .invalidVersionIdentifier:     return "Receipt has an invalid version identifier"
            case .invalidHash:                  return "Receipt has an invalid hash"
            case .expired:                      return "Receipt has expired"
        }
    }
}
