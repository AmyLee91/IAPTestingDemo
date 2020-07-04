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
        print(error.shortDescription())
        #endif
    }
    
    public static func event(error: IAPReceiptError) {
        #if DEBUG
        print(error.shortDescription())
        #endif
    }
    
    public static func event(event: IAPNotificaton) {
        #if DEBUG
        print(event.description())
        #endif
    }
}
