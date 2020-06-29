//
//  IAPOpenSSL.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

/// Helper functions used when working with OpenSSL to validate the App Store receipt
public struct IAPOpenSSL {
    
    static public func readASN1Data(ptr: UnsafePointer<UInt8>, length: Int) -> Data {
        return Data(bytes: ptr, count: length)
    }
    
    static public func readASN1Integer(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Int? {
        var type: Int32 = 0
        var xclass: Int32 = 0
        var length: Int = 0
        
        ASN1_get_object(&ptr, &length, &type, &xclass, maxLength)
        guard type == V_ASN1_INTEGER else {
            return nil
        }
        let integerObject = c2i_ASN1_INTEGER(nil, &ptr, length)
        let intValue = ASN1_INTEGER_get(integerObject)
        ASN1_INTEGER_free(integerObject)
        
        return intValue
    }
    
    static public func readASN1String(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> String? {
        var strClass: Int32 = 0
        var strLength = 0
        var strType: Int32 = 0
        
        var strPointer = ptr
        ASN1_get_object(&strPointer, &strLength, &strType, &strClass, maxLength)
        if strType == V_ASN1_UTF8STRING {
            let p = UnsafeMutableRawPointer(mutating: strPointer!)
            let utfString = String(bytesNoCopy: p, length: strLength, encoding: .utf8, freeWhenDone: false)
            return utfString
        }
        
        if strType == V_ASN1_IA5STRING {
            let p = UnsafeMutablePointer(mutating: strPointer!)
            let ia5String = String(bytesNoCopy: p, length: strLength, encoding: .ascii, freeWhenDone: false)
            return ia5String
        }
        
        return nil
    }
    
    static public func readASN1Date(ptr: inout UnsafePointer<UInt8>?, maxLength: Int) -> Date? {
        var str_xclass: Int32 = 0
        var str_length = 0
        var str_type: Int32 = 0
        
        // A date formatter to handle RFC 3339 dates in the GMT time zone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        
        var strPointer = ptr
        ASN1_get_object(&strPointer, &str_length, &str_type, &str_xclass, maxLength)
        guard str_type == V_ASN1_IA5STRING else {
            return nil
        }
        
        let p = UnsafeMutableRawPointer(mutating: strPointer!)
        if let dateString = String(bytesNoCopy: p, length: str_length, encoding: .ascii, freeWhenDone: false) {
            return formatter.date(from: dateString)
        }
        
        return nil
    }
    
}
