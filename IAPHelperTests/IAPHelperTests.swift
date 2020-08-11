//
//  IAPHelperTests.swift
//  IAPHelperTests
//
//  Created by Russell Archer on 30/07/2020.
//

import XCTest
import StoreKitTest
import IAPHelper

// Import the IAPTestingDemo module. This lets you write unit tests against *internal* properties and methods
@testable import IAPHelper

class IAPHelperTests: XCTestCase {
    private var session: SKTestSession! = try? SKTestSession(configurationFileNamed: IAPConstants.File())
    private var iap = IAPHelper.shared
    
    func testSetup() {
        XCTAssertTrue(iap.addedToPaymentQueue)
        iap.readConfigFile()
        XCTAssertTrue(iap.haveConfiguredProductIdentifiers)
    }
    
    func testReceipt() {
        let receipt = IAPReceipt()
        XCTAssertTrue(receipt.isReachable)
        XCTAssertTrue(receipt.load())
        XCTAssertTrue(receipt.validateSigning())
        XCTAssertTrue(receipt.read())
        XCTAssertTrue(receipt.validate())
    }
    
    func testPurchaseProduct() {
        session.disableDialogs = true

        let requestProductsExpectation = XCTestExpectation()
        let buyProductExpectation = XCTestExpectation()

        iap.requestProductsFromAppStore { notification in
            requestProductsExpectation.fulfill()

            XCTAssertTrue(notification == .requestProductsCompleted)

            guard self.iap.isAppStoreProductInfoAvailable else {
                XCTFail()
                return
            }

            guard let product = self.iap.getStoreProductFrom(id: "com.rarcher.flowers-small") else {
                XCTFail()
                return
            }

            self.iap.buyProduct(product) { notification in
                buyProductExpectation.fulfill()

                switch notification {
                case .purchaseCompleted(productId: let pid): fallthrough
                case .purchaseRestored(productId: let pid): XCTAssertTrue(pid == "com.rarcher.flowers-small")
                default: XCTFail()
                }
            }
        }

        wait(for: [requestProductsExpectation, buyProductExpectation], timeout: 30, enforceOrder: true)
    }
}
