//
//  IAPReceipt.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

public class IAPReceipt {
    
    fileprivate var receipt: UnsafeMutablePointer<PKCS7>?
    
    public var receiptIsPresent: Bool {
        return receipt == nil ? false : true
    }
    
    /// Load the receipt from the main bundle. Returns true if loaded, false if not found or an error occurs.
    public func load() -> Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            IAPLog.event(error: .receiptMissing)
            return false
        }
        
        guard let receiptData = try? Data(contentsOf: receiptUrl) else {
            IAPLog.event(error: .receiptMissing)
            return false
        }
        
        let receiptBIO = BIO_new(BIO_s_mem())
        let receiptBytes: [UInt8] = .init(receiptData)
        BIO_write(receiptBIO, receiptBytes, Int32(receiptData.count))

        let receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, nil)
        BIO_free(receiptBIO)

        guard receiptPKCS7 != nil else {
            print("Receipt bad format")
            return false
        }
        
        // Check that the container has a signature
        guard OBJ_obj2nid(receiptPKCS7!.pointee.type) == NID_pkcs7_signed else {
            print("Receipt bad PKCS7 signature")
            return false
        }
        
        // Check that the container contains data
        let receiptContents = receiptPKCS7!.pointee.d.sign.pointee.contents
        guard OBJ_obj2nid(receiptContents?.pointee.type) == NID_pkcs7_data else {
            print("Receipt bad PKCS7 type")
          return false
        }
        
        receipt = receiptPKCS7
        
        print("Receipt looks good! :-)")
        return true
    }
}
