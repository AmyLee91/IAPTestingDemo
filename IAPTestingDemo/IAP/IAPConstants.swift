//
//  IAPConfigurationConstants.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 24/06/2020.
//

import Foundation

/// Constants used in support of IAP operations.
public struct IAPConstants {
    
    /// Returns the appropriate .storekit configuration file to use for DEBUG and RELEASE builds.
    public static func File() -> String {
        #if DEBUG
        return "Configuration"
        #else
        return "ConfigurationRelease"
        #endif
    }
    
    /// Returns the file extension for the .storekit file.
    public static func FileExt() -> String { "storekit" }
    
    /// Returns the appropriate certificate to use for DEBUG and RELEASE builds. Used in receipt validation.
    public static func Certificate() -> String {
        #if DEBUG
        return "StoreKitTestCertificate"  // This is issued by StoreKit for local testing
        #else
        return "AppleIncRootCertificate"  // This is a Apple root certificate used when working in release with the real App Store
        #endif
    }
    
    /// Returns the file extension for the Apple certificate.
    public static func CertificateExt() -> String { "cer" }
}
