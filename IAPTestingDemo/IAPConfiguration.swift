//
//  IAPConfiguration.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 24/06/2020.
//

import Foundation

struct IAPConfiguration {
    
    static func File() -> String {
        #if DEBUG
        return "Configuration.storekit"
        #else
        return "ConfigurationRelease.storekit"
        #endif
    }
    
    static func Certificate() -> String {
        #if DEBUG
        return "StoreKitTestCertificate.cer"
        #else
        return "AppleIncRootCertificate.cer"
        #endif
    }
}
