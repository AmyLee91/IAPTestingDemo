//
//  IAPReceiptValidator.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

public class IAPReceiptValidator {
    
    private var receipt: IAPReceipt?
    
    public func validate() -> Bool {
        receipt = IAPReceipt()
        
        guard receipt!.load() else { return false }
        return true
    }
}
