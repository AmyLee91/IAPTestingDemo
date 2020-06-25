//
//  ViewController.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 23/06/2020.
//

import UIKit

/*
 
 Order of init events:
 
 * Load fallback list of purchased product ids from user defaults - need an IAPPersistence class
 * Read appropriate .storekit config file to get list of product ids of available products - need IAPConfiguration class
   (will be used to query App Store for localized details)
 * Host calls IAPHelper to requestProducts details from app store
 
 When making purchase:
 * Save purchased product id to user defaults
 :
 :
 
 */

class ViewController: UIViewController {
    var productIds: Set<ProductId>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let result = IAPConfiguration.read(filename: IAPConstants.File(), ext: IAPConstants.FileExt())
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
        IAPHelper.shared.addObserverForNotifications(observer: self, selector: #selector(self.handleIAPNotification(_:)))

        // Get localized info about our available in-app purchase products from the app store
        guard let pids = productIds else {
            print("No product IDs available")
            return
        }
        
        IAPHelper.shared.requestProducts(productIds: pids)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        IAPHelper.shared.removeObserverForNotifications(observer: self)
    }
    
    @IBAction func purchaseLargeFlowersTapped(_ sender: Any) {
        guard let product = IAPHelper.shared.getStoreProductFrom(id: "com.rarcher.flowers-large") else {
            print("Couldn't get SKProduct for large flowers")
            return
        }
        
        IAPHelper.shared.buyProduct(product)
    }
    
    @IBAction func purchaseSmallFlowersTapped(_ sender: Any) {
        guard let product = IAPHelper.shared.getStoreProductFrom(id: "com.rarcher.flowers-small") else {
            print("Couldn't get SKProduct for small flowers")
            return
        }
        
        IAPHelper.shared.buyProduct(product)
    }
    
    @objc func handleIAPNotification(_ notification: Notification) {

        switch notification.name.rawValue {
        case IAPNotificaton.requestProductsCompleted.key():
            print(IAPNotificaton.requestProductsCompleted.shortDescription())
            guard IAPHelper.shared.isStoreProductInfoAvailable else {
                print("No products available")
                return
            }
            
            print("Available products:")
            IAPHelper.shared.products?.forEach { product in
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

