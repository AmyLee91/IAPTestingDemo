//
//  IAPReceipt+Load.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 06/07/2020.
//

import Foundation

extension IAPReceipt {
    
    /// Load the receipt data from the main bundle and cache it. Basic validation of the receipt is done:
    /// We check its format, if it has a signature and if contains data. After loading the receipt you
    /// should call validateSigning() to check the receipt has been correctly signed, then read its IAP
    /// data using read(). You can then validate() the receipt.
    /// - Returns: Returns true if loaded correctly, false otherwise
    public func load() -> Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            mostRecentError = .missing
            delegate?.requestSendNotification(notification: .receiptMissing)
            return false
        }
        
        guard let data = try? Data(contentsOf: receiptUrl) else {
            mostRecentError = .badUrl
            delegate?.requestSendNotification(notification: .receiptLoadFailed)
            return false
        }
        
        let receiptBIO = BIO_new(BIO_s_mem())
        let receiptBytes: [UInt8] = .init(data)
        BIO_write(receiptBIO, receiptBytes, Int32(data.count))

        let receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, nil)
        BIO_free(receiptBIO)

        guard receiptPKCS7 != nil else {
            mostRecentError = .badFormat
            delegate?.requestSendNotification(notification: .receiptLoadFailed)
            return false
        }
        
        guard OBJ_obj2nid(receiptPKCS7!.pointee.type) == NID_pkcs7_signed else {
            mostRecentError = .badPKCS7Signature
            delegate?.requestSendNotification(notification: .receiptLoadFailed)
            return false
        }
        
        let receiptContents = receiptPKCS7!.pointee.d.sign.pointee.contents
        guard OBJ_obj2nid(receiptContents?.pointee.type) == NID_pkcs7_data else {
            mostRecentError = .badPKCS7Type
            delegate?.requestSendNotification(notification: .receiptLoadFailed)
            return false
        }
        
        receiptData = receiptPKCS7
        mostRecentError = .noError
        delegate?.requestSendNotification(notification: .receiptLoadCompleted)

        return true
    }
}
