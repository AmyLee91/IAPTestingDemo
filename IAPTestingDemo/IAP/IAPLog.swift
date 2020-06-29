//
//  IAPLog.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

public struct IAPLog {
  
    public static func event(error: IAPError) {
        #if DEBUG
        print("IAP error: \(error.shortDescription())")
        #endif
    }
    
    public static func event(error: IAPError, message: String) {
        #if DEBUG
        print("IAP error: \(error.shortDescription())\n\(message)")
        #endif
    }
    
    public static func event(event: IAPNotificaton) {
        #if DEBUG
        print("IAP notification: \(event.shortDescription())")
        #endif
    }
    
    public static func event(event: IAPNotificaton, message: String) {
        #if DEBUG
        print("IAP notification: \(event.shortDescription())\n\(message)")
        #endif
    }
    
    public static func event(productId: String, event: IAPNotificaton) {
        #if DEBUG
        print("IAP notification for ProductId \(productId): \(event.shortDescription())")
        #endif
    }
    
    public static func event(productId: String, event: IAPNotificaton, message: String) {
        #if DEBUG
        print("IAP notification for ProductId \(productId): \(event.shortDescription())\n\(message)")
        #endif
    }
}
