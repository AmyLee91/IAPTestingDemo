//
//  ViewController.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 23/06/2020.
//

import UIKit

class ViewController: UIViewController {
    var productIds: Set<ProductId>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Subscribe to IAPHelper notifications
        IAPHelper.shared.addObserverForNotifications(observer: self, selector: #selector(self.handleIAPNotification(_:)))
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

