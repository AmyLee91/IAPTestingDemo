//
//  IAPReceipt.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//
//  This class contains highly modified portions of code based on original Objective-C code
//  created by Hermes copyright (c) 2013 Robot Media. It also contains modified portions of
//  Swift code created by Bill Morefield copyright (c) 2018 Razeware LLC. 

import UIKit

public protocol IAPReceiptDelegate: class {
    func requestSendNotification(notification: IAPNotificaton)
}

/// IAPReceipt encasulates an Apple App Store-issued receipt. App Store receipts are a complete
/// record of a user's in-app purchase history. The receipt will contain a list of any in-app
/// purchases the user has made. This list can be used to validate a locally stored fall-back
/// list of purchased products. The fall-back list should be used when a connection to the App
/// Store is not possible (i.e. no network connectivity).
///
/// Note that:
///
/// - The receipt is a single encrypted file stored locally on the device and is accessible
///   through the main bundle (Bundle.main.appStoreReceiptURL)
/// - We use OpenSSL to access data in the receipt
/// - A new receipt is issued automatically (and to IAPHelper it appears as a refresh event)
///   by the App Store each time:
///     * an in-app purchase succeeds
///     * the app is re-installed
///     * an app update happens
///     * when previous in-app purchases are restored
public class IAPReceipt {
        
    // MARK:- Public properties
    
    /// The set of purchased ProductIds validated against the app's App Store receipt.
    /// The set of fallbackPurchasedProductIdentifiers held by IAPHelper should always
    /// be the same as validatedPurchasedProductIdentifiers. If they differ,
    /// fallbackPurchasedProductIdentifiers should be updated to be a copy of
    /// validatedPurchasedProductIdentifiers and persisted.
    public var validatedPurchasedProductIdentifiers = Set<ProductId>()
    
    /// Check to see if the receipt's URL is present and the receipt file itself is reachable.
    /// True if the receipt is available in the main bundle, false otherwise.
    public var isReachable: Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            mostRecentError = .badUrl
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptMissing)
            return false
        }
        
        guard let _ = try? receiptUrl.checkResourceIsReachable() else {
            mostRecentError = .missing
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptMissing)
            return false
        }
        
        return true
    }
    
    /// True if the receipt has been loaded and its data cached.
    public var isLoaded: Bool { receiptData == nil ? false : true }
    
    /// True if valid. If false then the host app should call refreshReceipt(completion:).
    public var isValid = false
    
    /// True if the receipt has been signed with a valid Apple X509 certificate.
    public var isValidSignature = false
    
    /// True if the receipt has been read and its metadata cached.
    public var hasBeenRead = false
    
    /// Keeps track of the most recent error condition.
    public var mostRecentError: IAPReceiptError = .noError

    /// IAPHelper delegate
    public weak var delegate: IAPReceiptDelegate?
    
    // MARK:- Private properties

    private var inAppReceipts: [IAPReceiptProductInfo] = []  // Array of purchased product info stored in the receipt
    private var receiptData: UnsafeMutablePointer<PKCS7>?    // The receipt's cached data
    
    // Data read from the receipt:
    private var bundleIdString: String?
    private var bundleVersionString: String?
    private var bundleIdData: Data?
    private var hashData: Data?
    private var opaqueData: Data?
    private var expirationDate: Date?
    private var receiptCreationDate: Date?
    private var originalAppVersion: String?
    
    // MARK:- Public methods
    
    /// Load the receipt data from the main bundle and cache it. Basic validation of the receipt is done:
    /// We check its format, if it has a signature and if contains data. After loading the receipt you
    /// should call validateSigning() to check the receipt has been correctly signed, then read its IAP
    /// data using read(). You can then validate() the receipt.
    /// - Returns: Returns true if loaded correctly, false otherwise
    public func load() -> Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            mostRecentError = .missing
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptMissing)
            return false
        }
        
        guard let data = try? Data(contentsOf: receiptUrl) else {
            mostRecentError = .badUrl
            IAPLog.event(error: mostRecentError)
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
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptLoadFailed)
            return false
        }
        
        guard OBJ_obj2nid(receiptPKCS7!.pointee.type) == NID_pkcs7_signed else {
            mostRecentError = .badPKCS7Signature
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptLoadFailed)
            return false
        }
        
        let receiptContents = receiptPKCS7!.pointee.d.sign.pointee.contents
        guard OBJ_obj2nid(receiptContents?.pointee.type) == NID_pkcs7_data else {
            mostRecentError = .badPKCS7Type
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptLoadFailed)
            return false
        }
        
        receiptData = receiptPKCS7
        mostRecentError = .noError
        delegate?.requestSendNotification(notification: .receiptLoadCompleted)

        return true
    }
    
    /// Check the receipt has been correctly signed with a valid Apple X509 certificate.
    /// - Returns: Returns true if correctly signed, false otherwise.
    public func validateSigning() -> Bool {
        guard receiptData != nil else {
            mostRecentError = .noData
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidateSigningFailed)
            return false
        }
        
        guard let rootCertUrl = Bundle.main.url(forResource: IAPConstants.Certificate(), withExtension: IAPConstants.CertificateExt()),
              let rootCertData = try? Data(contentsOf: rootCertUrl) else {
            
            mostRecentError = .invalidAppleRootCertificate
            IAPLog.event(error: mostRecentError)
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
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidateSigningFailed)
            return false
        }
        
        isValidSignature = true
        mostRecentError = .noError
        delegate?.requestSendNotification(notification: .receiptValidateSigningCompleted)

        return true
    }
    
    /// Read internal receipt data into a cache.
    /// - Returns: Returns true if all expected data was present and correctly read from the receipt, false otherwise.
    public func read() -> Bool {
        // Get a pointer to the start and end of the ASN.1 payload
        let receiptSign = receiptData?.pointee.d.sign
        let octets = receiptSign?.pointee.contents.pointee.d.data
        var pointer = UnsafePointer(octets?.pointee.data)
        let end = pointer!.advanced(by: Int(octets!.pointee.length))
        
        var type: Int32 = 0
        var xclass: Int32 = 0
        var length: Int = 0
        
        ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: end))
        guard type == V_ASN1_SET else {
            mostRecentError = .unexpectedASN1Type
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptReadFailed)
            return false
        }
        
        while pointer! < end {
            ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: end))
            guard type == V_ASN1_SEQUENCE else {
                mostRecentError = .unexpectedASN1Type
                IAPLog.event(error: mostRecentError)
                delegate?.requestSendNotification(notification: .receiptReadFailed)
                return false
            }
            
            guard let attributeType = IAPOpenSSL.asn1Int(p: &pointer, expectedLength: length) else {
                mostRecentError = .unexpectedASN1Type
                IAPLog.event(error: mostRecentError)
                delegate?.requestSendNotification(notification: .receiptReadFailed)
                return false
            }
            
            guard let _ = IAPOpenSSL.asn1Int(p: &pointer, expectedLength: pointer!.distance(to: end)) else {
                mostRecentError = .unexpectedASN1Type
                IAPLog.event(error: mostRecentError)
                delegate?.requestSendNotification(notification: .receiptReadFailed)
                return false
            }
            
            ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: end))
            guard type == V_ASN1_OCTET_STRING else {
                mostRecentError = .unexpectedASN1Type
                IAPLog.event(error: mostRecentError)
                delegate?.requestSendNotification(notification: .receiptReadFailed)
                return false
            }
            
            var p = pointer
            switch IAPOpenSSLAttributeType(rawValue: attributeType) {
                    
                case .BudleVersion: bundleVersionString         = IAPOpenSSL.asn1String(p: &p, expectedLength: length)
                case .ReceiptCreationDate: receiptCreationDate  = IAPOpenSSL.asn1Date(p: &p, expectedLength: length)
                case .OriginalAppVersion: originalAppVersion    = IAPOpenSSL.asn1String(p: &p, expectedLength: length)
                case .ExpirationDate: expirationDate            = IAPOpenSSL.asn1Date(p: &p, expectedLength: length)
                case .OpaqueValue: opaqueData                   = IAPOpenSSL.asn1Data(p: p!, expectedLength: length)
                case .ComputedGuid: hashData                    = IAPOpenSSL.asn1Data(p: p!, expectedLength: length)
                    
                case .BundleIdentifier:
                    bundleIdString                              = IAPOpenSSL.asn1String(p: &pointer, expectedLength: length)
                    bundleIdData                                = IAPOpenSSL.asn1Data(p: pointer!, expectedLength: length)
                    
                case .IAPReceipt:
                    var iapStartPtr = pointer
                    let receiptProductInfo = IAPReceiptProductInfo(with: &iapStartPtr, payloadLength: length)
                    if let rpi = receiptProductInfo {
                        inAppReceipts.append(rpi)
                        if let pid = rpi.productIdentifier { validatedPurchasedProductIdentifiers.insert(pid) }
                    }
                    
                default: break  // Ignore other attributes in receipt
            }
            
            // Advance pointer to the next item
            pointer = pointer!.advanced(by: length)
        }
        
        hasBeenRead = true
        mostRecentError = .noError
        delegate?.requestSendNotification(notification: .receiptReadCompleted)
        
        return true
    }
    
    /// Perform on-device (no network connection required) validation of the app's receipt.
    /// Returns false if the receipt is invalid or missing, in which case your app should call
    /// refreshReceipt(completion:) to request an updated receipt from the app store. This will
    /// result in the user being prompted for their App Store credentials.
    ///
    /// We validate the receipt to ensure that it was:
    ///
    /// - Created and signed using the Apple x509 root certificate via the App Store
    /// - Issued for the same version of this app and the user's device
    ///
    /// At this point a list of locally stored purchased product ids should have been loaded from the UserDefaults
    /// dictionary. We need to validate these product ids against the App Store receipt's collection of purchased
    /// product ids to see that they match. If there are no locally stored purchased product ids (i.e. the user
    /// hasn't purchased anything) then we don't attempt to validate the receipt as this would trigger a prompt
    /// for the user to provide their App Store credentials (and this isn't a good experience for a new user of
    /// the app to immediately be asked to sign-in). Note that if the user has previously purchased products
    /// then either using the Restore feature or attempting to re-purchase the product will result in a refreshed
    /// receipt and the product id of the product will be stored locally in the UserDefaults dictionary.
    /// - Returns: Returns true if the receipt is valid; false otherwise.
    public func validate() -> Bool {
        guard let idString = bundleIdString,
              let version = bundleVersionString,
              let _ = opaqueData,
              let hash = hashData else {
            
            mostRecentError = .missingComponent
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidationFailed)
            return false
        }
        
        guard let appBundleId = Bundle.main.bundleIdentifier else {
            mostRecentError = .unknownFailure
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidationFailed)
            return false
        }
        
        guard idString == appBundleId else {
            mostRecentError = .invalidBundleIdentifier
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidationFailed)
            return false
        }
        
        guard let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            mostRecentError = .unknownFailure
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidationFailed)
            return false
        }
        
        guard version == appVersionString else {
            mostRecentError = .invalidVersionIdentifier
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidationFailed)
            return false
        }
        
        guard hash == computeHash() else {
            mostRecentError = .invalidHash
            IAPLog.event(error: mostRecentError)
            delegate?.requestSendNotification(notification: .receiptValidationFailed)
            return false
        }
        
        if let expirationDate = expirationDate {
            if expirationDate < Date() {
                mostRecentError = .expired
                IAPLog.event(error: mostRecentError)
                delegate?.requestSendNotification(notification: .receiptValidationFailed)
                return false
            }
        }
        
        isValid = true
        mostRecentError = .noError
        delegate?.requestSendNotification(notification: .receiptValidationCompleted)
        
        return true
    }
    
    /// Compare the set of fallback ProductIds with the receipt's validatedPurchasedProductIdentifiers
    /// - Parameter fallbackPids: Set of locally stored fallback ProductIds
    /// - Returns: Returns true if both sets are the same, false otherwise
    public func validateFallbackProductIds(fallbackPids: Set<ProductId>) -> Bool {
        return fallbackPids == validatedPurchasedProductIdentifiers
    }
    
    // MARK:- Private methods
    
    private func getDeviceIdentifier() -> Data {
        let device = UIDevice.current
        var uuid = device.identifierForVendor!.uuid
        let addr = withUnsafePointer(to: &uuid) { (p) -> UnsafeRawPointer in
            UnsafeRawPointer(p)
        }
        let data = Data(bytes: addr, count: 16)
        return data
    }
    
    private func computeHash() -> Data {
        let identifierData = getDeviceIdentifier()
        var ctx = SHA_CTX()
        SHA1_Init(&ctx)
        
        let identifierBytes: [UInt8] = .init(identifierData)
        SHA1_Update(&ctx, identifierBytes, identifierData.count)
        
        let opaqueBytes: [UInt8] = .init(opaqueData!)
        SHA1_Update(&ctx, opaqueBytes, opaqueData!.count)
        
        let bundleBytes: [UInt8] = .init(bundleIdData!)
        SHA1_Update(&ctx, bundleBytes, bundleIdData!.count)
        
        var hash: [UInt8] = .init(repeating: 0, count: 20)
        SHA1_Final(&hash, &ctx)
        return Data(bytes: hash, count: 20)
    }
}



