//
//  IAPLog.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

public struct IAPLog {
  
    public static func event(error: IAPConfigurationError) {
        #if DEBUG
        print("IAP configuration error: \(0)")
        #endif
    }
    
//    public static func event(product: SKProduct?, event: IAPNotificaton, message: String? = nil) {
//        #if DEBUG
//        print("\(event.shortDescription())")
//
//        if let prod = product {
//            print("  Product ID : \(prod.productIdentifier)")
//            print("  Title      : \(prod.localizedTitle)")
//            print("  Value      : \(prod.price)")
//            print("  Currency   : \(prod.priceLocale.currencyCode ?? "Unknown")")
//        }
//
//        if let msg = message {
//            print("  Message    : \(msg)")
//        }
//        #endif
//    }
    
    public static func event(event: IAPNotificaton) {
//        IAPLog.event(product: nil, event:  event)
    }
    
    public static func event(productId: String, event: IAPNotificaton) {
//        IAPLog.event(product: NavUtils.appDelegate.iap.getStoreProductFrom(id: productId), event:  event)
    }
    
    public static func event(productId: String, event: IAPNotificaton, message: String) {
//        IAPLog.event(product: NavUtils.appDelegate.iap.getStoreProductFrom(id: productId), event: event, message: message)
    }
}
