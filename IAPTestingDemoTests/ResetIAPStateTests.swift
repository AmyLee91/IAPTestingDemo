//
//  ResetIAPStateTests.swift
//  IAPTestingDemoTests
//
//  Created by Russell Archer on 27/06/2020.
//

import XCTest

// Import the IAPTestingDemo module. This lets you write unit tests against *internal* properties and methods
@testable import IAPTestingDemo

class ResetIAPStateTests: XCTestCase {
//    private var session: SKTestSession!
    
    //    override func setUpWithError() throws {
    //        // This method is called before the invocation of each test method in the class
    //        session = try? SKTestSession(configurationFileNamed: IAPConstants.File())
    //        guard session != nil else {
    //            XCTFail()
    //            return
    //        }
    //    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    //    func testClearReceipt() {
    //        session.disableDialogs = true
    //        session.clearTransactions()
    //    }
    //
    //    func testClearUserDefaultsFallbackPurchases() {
    //        guard iap.haveFallbackPurchasedProductIdentifiers else { return }
    //
    //        iap.fallbackPurchasedProductIdentifiers!.forEach { pid in
    //            UserDefaults.standard.removeObject(forKey: pid)
    //        }
    //    }
}
