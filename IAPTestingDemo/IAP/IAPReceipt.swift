//
//  IAPReceipt.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import UIKit

public class IAPReceipt {
        
    /// True if the receipt has been loaded and its data cached
    public var dataIsLoaded: Bool { return receiptData == nil ? false : true }
    
    /// Check to see if the receipt's URL is present and the receipt file itself is reachable.
    /// True if the receipt is available in the main bundle, false otherwise.
    public var isReachable: Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return false }
        let available = try? receiptUrl.checkResourceIsReachable()
        
        return available == nil ? false : true
    }
    
    // Cache of internal receipt data loaded via the load() method.
    public var receiptData: UnsafeMutablePointer<PKCS7>?
    public var bundleIdString: String?
    public var bundleVersionString: String?
    public var bundleIdData: Data?
    public var hashData: Data?
    public var opaqueData: Data?
    public var expirationDate: Date?
    public var receiptCreationDate: Date?
    public var originalAppVersion: String?
    private var inAppReceipts: [IAPReceiptEntity] = []  // Property cannot be declared public because its type uses an internal type
    
    public func iapProducts() -> [String]? {
        var prods = [String]()
        for p in inAppReceipts {
            print("Product ID: \(p.productIdentifier ?? "unknown")")
            prods.append(p.productIdentifier ?? "?")
        }
        return prods
    }
    
    /// Load the receipt data from the main bundle and cache it. Basic validation of the receipt is done:
    /// We check its format, if it has a signature and if contains data. After loading the receipt you
    /// should call validateSigning() to check the receipt has been correctly signed, then read its IAP
    /// data using read(). You can then validate() the receipt.
    /// - Returns: Returns true if loaded, false if not found or an error occurs.
    public func load() -> Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            IAPLog.event(error: .receiptMissing)
            return false
        }
        
        guard let data = try? Data(contentsOf: receiptUrl) else {
            IAPLog.event(error: .receiptMissing)
            return false
        }
        
        let receiptBIO = BIO_new(BIO_s_mem())
        let receiptBytes: [UInt8] = .init(data)
        BIO_write(receiptBIO, receiptBytes, Int32(data.count))

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
        
        receiptData = receiptPKCS7
        
        print("Receipt loaded OK")
        return true
    }
    
    /// Check the receipt has been correctly signed with a valid Apple X509 certificate.
    /// - Returns: Returns true if correctly signed, false otherwise.
    public func validateSigning() -> Bool {
        guard receiptData != nil else {
            print("No receipt data")
            return false
        }
        
        guard let rootCertUrl = Bundle.main.url(forResource: IAPConstants.File(), withExtension: IAPConstants.FileExt()),
              let rootCertData = try? Data(contentsOf: rootCertUrl)
        else {
            print("invalidAppleRootCertificate")
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
            print("failedAppleSignature")
            return false
        }
        
        print("Receipt signing validated OK")
        return true
    }
    
    public func read() -> Bool {
        // Get a pointer to the start and end of the ASN.1 payload
        let receiptSign = receiptData?.pointee.d.sign
        let octets = receiptSign?.pointee.contents.pointee.d.data
        var ptr = UnsafePointer(octets?.pointee.data)
        let end = ptr!.advanced(by: Int(octets!.pointee.length))
        
        var type: Int32 = 0
        var xclass: Int32 = 0
        var length: Int = 0
        
        ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
        guard type == V_ASN1_SET else {
            print("unexpectedASN1Type")
            return false
        }
        
        // 1
        while ptr! < end {
            // 2
            ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
            guard type == V_ASN1_SEQUENCE else {
                print("unexpectedASN1Type")
                return false
            }
            
            // 3
            guard let attributeType = IAPOpenSSL.readASN1Integer(ptr: &ptr, maxLength: length) else {
                print("unexpectedASN1Type")
                return false
            }
            
            // 4
            guard let _ = IAPOpenSSL.readASN1Integer(ptr: &ptr, maxLength: ptr!.distance(to: end)) else {
                print("unexpectedASN1Type")
                return false
            }
            
            // 5
            ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
            guard type == V_ASN1_OCTET_STRING else {
                print("unexpectedASN1Type")
                return false
            }
            
            switch attributeType {
                case 2: // The bundle identifier
                    var stringStartPtr = ptr
                    bundleIdString = IAPOpenSSL.readASN1String(ptr: &stringStartPtr, maxLength: length)
                    bundleIdData = IAPOpenSSL.readASN1Data(ptr: ptr!, length: length)
                    
                case 3: // Bundle version
                    var stringStartPtr = ptr
                    bundleVersionString = IAPOpenSSL.readASN1String(ptr: &stringStartPtr, maxLength: length)
                    
                case 4: // Opaque value
                    let dataStartPtr = ptr!
                    opaqueData = IAPOpenSSL.readASN1Data(ptr: dataStartPtr, length: length)
                    
                case 5: // Computed GUID (SHA-1 Hash)
                    let dataStartPtr = ptr!
                    hashData = IAPOpenSSL.readASN1Data(ptr: dataStartPtr, length: length)
                    
                case 12: // Receipt Creation Date
                    var dateStartPtr = ptr
                    receiptCreationDate = IAPOpenSSL.readASN1Date(ptr: &dateStartPtr, maxLength: length)
                    
                case 17: // IAP Receipt
                    var iapStartPtr = ptr
                    let parsedReceipt = IAPReceiptEntity(with: &iapStartPtr, payloadLength: length)
                    if let newReceipt = parsedReceipt {
                        inAppReceipts.append(newReceipt)
                        print("Found purchased product in receipt: \(newReceipt.productIdentifier ?? "unknown pid")")
                    }
                    
                case 19: // Original App Version
                    var stringStartPtr = ptr
                    originalAppVersion = IAPOpenSSL.readASN1String(ptr: &stringStartPtr, maxLength: length)
                    
                case 21: // Expiration Date
                    var dateStartPtr = ptr
                    expirationDate = IAPOpenSSL.readASN1Date(ptr: &dateStartPtr, maxLength: length)
                    
                default: // Ignore other attributes in receipt
                    break
            }
            
            // Advance pointer to the next item
            ptr = ptr!.advanced(by: length)
        }
        
        return true
    }
    
    public func validate() -> Bool {
        return true
    }
}

