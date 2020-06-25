//
//  IAPConfigurationConstants.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 24/06/2020.
//

import Foundation

public struct IAPConstants {
    
    public static func File() -> String {
        #if DEBUG
        return "Configuration"
        #else
        return "ConfigurationRelease"
        #endif
    }
    
    public static func FileExt() -> String { "storekit" }
    
    public static func Certificate() -> String {
        #if DEBUG
        return "StoreKitTestCertificate.cer"
        #else
        return "AppleIncRootCertificate.cer"
        #endif
    }
}
