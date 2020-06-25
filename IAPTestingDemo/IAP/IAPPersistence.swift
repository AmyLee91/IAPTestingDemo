//
//  IAPPersistence.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

/// IAPPersistence contains static methods to load and save 'fallback' purchase information.
/// If a product is purchased a Bool is created in UserDefaults. Its key will be the ProductId.
public struct IAPPersistence: IAPPersistenceProtocol {
    
    public static func savePurchasedState(for productId: ProductId, purchased: Bool = true) {
        print("Saving purchased state for ProductId \(productId)")
        UserDefaults.standard.set(purchased, forKey: productId)
    }
    
    public static func loadPurchasedState(for productId: ProductId) -> Bool {
        print("Attempting to load purchased ProductId \(productId)...")
        return UserDefaults.standard.bool(forKey: productId)
    }
    
    public static func loadPurchasedState(for productIds: Set<ProductId>) -> [(productId: ProductId, purchased: Bool)]? {
        print("Attempting to load purchased state for list of ProductIds...")

        var purchasedProductIds = [(productId: ProductId, purchased: Bool)]()
        productIds.forEach { productId in
            let p = UserDefaults.standard.bool(forKey: productId)
            print("\(productId) was purchased: \(p)")
            purchasedProductIds.append((productId: productId, purchased: UserDefaults.standard.bool(forKey: productId)))
        }
        
        return purchasedProductIds.count > 0 ? purchasedProductIds : nil
    }
    
    public static func loadPurchasedProductIds(for productIds: Set<ProductId>) -> Set<ProductId>? {
        print("Attempting to load purchased ProductIds...")

        var purchasedProductIds = Set<ProductId>()
        productIds.forEach { productId in
            let purchased = UserDefaults.standard.bool(forKey: productId)
            print("\(productId) was purchased: \(purchased)")
            
            if purchased { purchasedProductIds.insert(productId) }
        }
        
        return purchasedProductIds.count > 0 ? purchasedProductIds : nil
    }
}
