//
//  ViewController.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 23/06/2020.
//

import UIKit

class ViewController: UIViewController {
    var iap = IAPHelper.shared
    var productIds: Set<ProductId>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let result = IAPConfigurationReader.read(filename: "Configuration", ext: "storekit")
        switch result {
            case .failure(let error):
                print(error)
                break
                
            case .success(let configuration):
                guard let products = configuration.products, products.count > 0 else { break }
                productIds = Set<ProductId>(products.compactMap { product in product.productID })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Subscribe to IAPHelper notifications
        iap.addObserverForNotifications(observer: self, selector: #selector(self.handleIAPNotification(_:)))

        // Get localized info about our available in-app purchase products from the app store
        guard let pids = productIds else {
            print("No product IDs available")
            return
        }
        
        iap.requestProducts(productIds: pids)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        iap.removeObserverForNotifications(observer: self)
    }
    
    @IBAction func purchaseLargeFlowersTapped(_ sender: Any) {
        guard let product = iap.getStoreProductFrom(id: "com.rarcher.flowers-large") else {
            print("Couldn't get SKProduct for large flowers")
            return
        }
        
        iap.buyProduct(product)
    }
    
    @IBAction func purchaseSmallFlowersTapped(_ sender: Any) {
        guard let product = iap.getStoreProductFrom(id: "com.rarcher.flowers-small") else {
            print("Couldn't get SKProduct for small flowers")
            return
        }
        
        iap.buyProduct(product)
    }
    
    @objc func handleIAPNotification(_ notification: Notification) {

        switch notification.name.rawValue {
        case IAPNotificaton.requestProductsCompleted.key():
            print(IAPNotificaton.requestProductsCompleted.shortDescription())
            guard iap.isStoreProductInfoAvailable else {
                print("No products available")
                return
            }
            
            print("Available products:")
            iap.products?.forEach { product in
                print("\(product.productIdentifier) : \(product.localizedTitle)")
            }
            break

        case IAPNotificaton.requestProductsFailed.key():
            print(IAPNotificaton.requestProductsFailed.shortDescription())
            break

        case IAPNotificaton.purchaseCompleted.key():
            print(IAPNotificaton.purchaseCompleted.shortDescription())
            break

        case IAPNotificaton.purchaseRestored.key():
            print(IAPNotificaton.purchaseRestored.shortDescription())
            break
            
        case IAPNotificaton.purchaseRestoreFailed.key():
            print(IAPNotificaton.purchaseRestoreFailed.shortDescription())
            break

        default: return
        }
    }
}

