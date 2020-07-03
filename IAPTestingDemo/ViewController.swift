//
//  ViewController.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 23/06/2020.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IAPHelper.shared.requestProductsFromAppStore { e in
            if e != nil {
                print(e!.shortDescription())
                return
            }

            print("Got available products from the App Store...")
            IAPHelper.shared.products?.forEach {
                print($0.productIdentifier)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Subscribe to IAPHelper notifications
        IAPHelper.shared.addObserverForNotifications(observer: self, selector: #selector(self.handleIAPNotification(_:)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        IAPHelper.shared.removeObserverForNotifications(observer: self)
    }
    
    @IBAction func purchaseLargeFlowersTapped(_ sender: Any) {
        guard let product = IAPHelper.shared.getStoreProductFrom(id: "com.rarcher.flowers-large") else { return }
        IAPHelper.shared.buyProduct(product)
    }
    
    @IBAction func purchaseSmallFlowersTapped(_ sender: Any) {
        guard let product = IAPHelper.shared.getStoreProductFrom(id: "com.rarcher.flowers-small") else { return }
        IAPHelper.shared.buyProduct(product)
    }
    
    @objc func handleIAPNotification(_ notification: Notification) {
        
        switch notification.name.rawValue {
        case IAPNotificaton.requestProductsCompleted.key():
            break

        case IAPNotificaton.requestProductsFailed.key():
            break

        case IAPNotificaton.purchaseCompleted.key():
            break

        case IAPNotificaton.purchaseRestored.key():
            break
            
        case IAPNotificaton.purchaseRestoreFailed.key():
            break

        default:
            return
        }
    }
}

