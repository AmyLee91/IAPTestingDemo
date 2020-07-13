//
//  ViewController.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 23/06/2020.
//

import UIKit

class ViewController: UIViewController {
    
    private var tableView = UITableView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        IAPHelper.shared.processNotifications { notification in
            switch notification {
            case .appStoreChanged:
                // The App Store storefront has changed (e.g. from US to UK). We need to get localized prices, etc.
                IAPHelper.shared.requestProductsFromAppStore(forceRefresh: true) { _ in
                    self.tableView.reloadData()
                }
                
            case .appStoreRevokedEntitlements(productId: _):
                // The App Store issued a refund for a product. Remove access from the user
                IAPHelper.shared.requestProductsFromAppStore(forceRefresh: true) { _ in
                    self.tableView.reloadData()
                }
            
            default: break
            }
        }
        
        configureTableView()
        configureStore()
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
       
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
       
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)  // Removes empty cells
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseId)
        tableView.register(RestoreCell.self, forCellReuseIdentifier: RestoreCell.reuseId)
    }
    
    private func configureStore() {
        IAPHelper.shared.requestProductsFromAppStore { _ in
            self.tableView.reloadData()
        }
    }
}

// MARK:- UITableViewDelegate, UITableViewDataSource

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    internal func numberOfSections(in tableView: UITableView) -> Int { 2 }

    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 { return RestoreCell.cellHeight }
        
        var purchased = false
        if let p = IAPHelper.shared.products?[indexPath.row], IAPHelper.shared.isProductPurchased(id: p.productIdentifier) { purchased = true }
        
        return purchased ? ProductCell.cellHeightPurchased : ProductCell.cellHeightUnPurchased
    }
        
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return IAPHelper.shared.products == nil ? 0 : IAPHelper.shared.products!.count }
        else { return 1 }
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 { return configureProductCell(for: indexPath) }
        return configureRestoreCell()
    }
    
    private func configureProductCell(for indexPath: IndexPath) -> ProductCell {
        guard let products = IAPHelper.shared.products else { return ProductCell() }
        
        let product = products[indexPath.row]
        var price = IAPHelper.getLocalizedPriceFor(product: product)
        if price == nil { price = "Price unknown" }
        
        let productInfo = ProductInfo(id: product.productIdentifier,
                                      imageName: product.productIdentifier,
                                      localizedTitle: product.localizedTitle,
                                      localizedDescription: product.localizedDescription,
                                      localizedPrice: price!,
                                      purchased: IAPHelper.shared.isProductPurchased(id: product.productIdentifier))
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.reuseId) as! ProductCell
        cell.delegate = self
        cell.productInfo = productInfo
        
        return cell
    }
    
    private func configureRestoreCell() -> RestoreCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RestoreCell.reuseId) as! RestoreCell
        cell.delegate = self
        return cell
    }
}

// MARK:- ProductCellDelegate

extension ViewController: ProductCellDelegate {
    
    internal func requestBuyProduct(productId: ProductId) {
        guard let product = IAPHelper.shared.getStoreProductFrom(id: productId) else { return }
        IAPHelper.shared.buyProduct(product) { _ in
            self.tableView.reloadData()  // Reload data for a completed purchase, failure or cancellation
        }
    }
}

// MARK:- RestoreCellDelegate

extension ViewController: RestoreCellDelegate {
    
    internal func requestRestore() {
        IAPHelper.shared.restorePurchases() { _ in
            self.tableView.reloadData()  // Reload data for a success or failure
        }
    }
}
