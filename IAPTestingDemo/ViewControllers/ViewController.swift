//
//  ViewController.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 23/06/2020.
//

import UIKit

class ViewController: UIViewController {
    
    var tableView = UITableView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configureStore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Subscribe to IAPHelper notifications
        IAPHelper.shared.addObserverForNotifications(notifications: [.purchaseCompleted, .purchaseRestored], observer: self, selector: #selector(self.handleIAPNotification(_:)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        IAPHelper.shared.removeObserverForNotifications(notifications: [.purchaseCompleted, .purchaseRestored], observer: self)
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
    }
    
    private func configureStore() {
        IAPHelper.shared.requestProductsFromAppStore { error in
            if error != nil { return }
            self.tableView.reloadData()
        }
    }
    
    @objc func handleIAPNotification(_ notification: Notification) {
        print(notification.name.rawValue)
        
        switch notification.name.rawValue {
        case IAPNotificaton.purchaseCompleted.key(): handlePurchaseCompleted(notification)
        case IAPNotificaton.purchaseRestored.key():  handlePurchaseCompleted(notification, restore: true)
        default: return
        }
    }
    
    private func handlePurchaseCompleted(_ notification: Notification, restore: Bool = false) {
        // An IAP product has been successfully purchased
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 130 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        IAPHelper.shared.products == nil ? 0 : IAPHelper.shared.products!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let products = IAPHelper.shared.products else { return UITableViewCell() }
        
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
}

extension ViewController: ProductCellDelegate {
    
    func requestBuyProduct(productId: ProductId) {
        guard let product = IAPHelper.shared.getStoreProductFrom(id: productId) else { return }
        IAPHelper.shared.buyProduct(product)
    }
}
