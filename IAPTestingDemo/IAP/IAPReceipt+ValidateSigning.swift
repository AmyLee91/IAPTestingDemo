//
//  IAPReceipt+ValidateSigning.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 06/07/2020.
//

import Foundation

extension IAPReceipt {
    
    /// Check the receipt has been correctly signed with a valid Apple X509 certificate.
    /// - Returns: Returns true if correctly signed, false otherwise.
    public func validateSigning() -> Bool {
        guard receiptData != nil else {
            mostRecentError = .noData
            delegate?.requestSendNotification(notification: .receiptValidateSigningFailed)
            return false
        }
        
        guard let rootCertUrl = Bundle.main.url(forResource: IAPConstants.Certificate(), withExtension: IAPConstants.CertificateExt()),
              let rootCertData = try? Data(contentsOf: rootCertUrl) else {
            
            mostRecentError = .invalidAppleRootCertificate
            delegate?.requestSendNotification(notification: .receiptValidateSigningFailed)
            return false
        }
        
        let rootCertBio = BIO_new(BIO_s_mem())
        let rootCertBytes: [UInt8] = .init(rootCertData)
        BIO_write(rootCertBio, rootCertBytes, Int32(rootCertData.count))
        let rootCertX509 = d2i_X509_bio(rootCertBio, nil)
        BIO_free(rootCertBio)
        
        let store = X509_STORE_new()
        X509_STORE_add_cert(store, rootCertX509)
        
        OPENSSL_init_crypto(UInt64(OPENSSL_INIT_ADD_ALL_DIGESTS), nil)
        
        // If PKCS7_NOVERIFY is set the signer's certificates are not chain verified.
        // This is required when using the local testing StoreKitTestCertificate.cer certificate.
        // TODO: Check this works OK when using the real AppleIncRootCertificate.cer certificate:
        #if DEBUG
        let verificationResult = PKCS7_verify(receiptData, nil, store, nil, nil, PKCS7_NOVERIFY)
        #else
        let verificationResult = PKCS7_verify(receiptData, nil, store, nil, nil, 0)
        #endif
        
        guard verificationResult == 1  else {
            mostRecentError = .failedAppleSignature
            delegate?.requestSendNotification(notification: .receiptValidateSigningFailed)
            return false
        }
        
        isValidSignature = true
        mostRecentError = .noError
        delegate?.requestSendNotification(notification: .receiptValidateSigningCompleted)

        return true
    }
}
