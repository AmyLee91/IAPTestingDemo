//
//  IAPSetupTests.swift
//  IAPTestingDemoTests
//
//  Created by Russell Archer on 26/06/2020.
//

import XCTest
import StoreKitTest

// Import the IAPTestingDemo module. This lets you write unit tests against *internal* properties and methods
@testable import IAPTestingDemo

class IAPSetupTests: XCTestCase {
    private var session: SKTestSession!
    
    func testSetup() {        
        session = try? SKTestSession(configurationFileNamed: IAPConstants.File())
        XCTAssertNotNil(session)
        
        session.disableDialogs = true
        session.clearTransactions()
        
        // Clear the fallbackPurchasedProductIdentifiers from UserDefaults
        if let fbpids = IAPHelper.shared.fallbackPurchasedProductIdentifiers {
            fbpids.forEach { pid in
                UserDefaults.standard.removeObject(forKey: pid)
            }
        }
        
        XCTAssertFalse(IAPHelper.shared.addedToPaymentQueue)
        IAPHelper.shared.addToPaymentQueue()
        XCTAssertTrue(IAPHelper.shared.addedToPaymentQueue)
        
        XCTAssertFalse(IAPHelper.shared.haveConfiguredProductIdentifiers)
        IAPHelper.shared.readConfigFile()
        XCTAssertTrue(IAPHelper.shared.haveConfiguredProductIdentifiers)
        
        XCTAssertFalse(IAPHelper.shared.haveFallbackPurchasedProductIdentifiers)
        IAPHelper.shared.loadFallbackProductIds()
        XCTAssertTrue(IAPHelper.shared.haveFallbackPurchasedProductIdentifiers)
        
//        XCTAssertTrue(IAPHelper.shared.receiptAvailable())
        
        XCTAssertFalse(IAPHelper.shared.isReceiptValid)
//        XCTAssertNotNil(IAPHelper.shared.validateReceipt())
//        XCTAssertTrue(IAPHelper.shared.isReceiptValid)
    }
    
    
    
    
    
    
    
    
    
    
    
//    func testRequestProductsFromAppStore() {
//        // Create an expected outcome for an *asynchronous* test (background image download)
//        let configIAPHelperExpectation = XCTestExpectation()
//        wait(for: [configIAPHelperExpectation], timeout: 10.0)  // Wait up to 10 secs for the expectation to be fulfilled
//        let iap = IAPHelper.shared
//        configIAPHelperExpectation.fulfill()
//
//
//        //iap.requestProductsFromAppStore()
//    }
    
//    func testPurchaseProduct() {
//        guard let product = iap.getStoreProductFrom(id: "com.rarcher.flowers-small") else {
//            XCTFail()
//            return
//        }
//
//        IAPHelper.shared.buyProduct(product)
//    }

}
