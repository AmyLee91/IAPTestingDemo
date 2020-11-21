//
//  GetProductsCell.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 30/10/2020.
//

import UIKit

class GetProductsCell: UITableViewCell {

    public static let reuseId = "GetProductsCell"
    public static let cellHeight = CGFloat(55)
    
    public var parentViewController: ViewController?
    private var getProductsButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) { fatalError("Storyboard not supported") }
    
    private func configureCell() {
        // You must add subviews to the *contentView*
        contentView.addSubview(getProductsButton)
        
        translatesAutoresizingMaskIntoConstraints = false

        getProductsButton.translatesAutoresizingMaskIntoConstraints = false
        getProductsButton.backgroundColor = .systemBlue
        getProductsButton.setTitle("Get Product Info", for: .normal)
        getProductsButton.layer.cornerRadius = 10
        getProductsButton.setTitleColor(.white, for: .normal)
        getProductsButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        getProductsButton.addTarget(self, action: #selector(getProductsButtonTapped), for: .touchUpInside)
        
        // The layout of the cell is as follows:
        //
        // +------------------------------+
        // | [Get Localized Product Info] |
        // +------------------------------+
        
        let padding: CGFloat = 5
        NSLayoutConstraint.activate([
            getProductsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2 * padding),
            getProductsButton.heightAnchor.constraint(equalToConstant: 30),
            getProductsButton.widthAnchor.constraint(equalToConstant: 170),
            getProductsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }
    
    @objc internal func getProductsButtonTapped() {
        parentViewController?.configureProducts()
    }
}
