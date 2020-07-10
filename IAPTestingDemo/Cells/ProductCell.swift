//
//  ProductCell.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 09/07/2020.
//

import UIKit

/*
 
 An image for each product is stored in the Assets catalog.
 The image name is the product id (e.g. com.rarcher.flowers-large).
 All images are copyright free from Pixabay.com.
 
 The layout of the cell is as follows:
 
 +-----------------------------------------+
 | +---------+ [Title                    ] |
 | | product | [Description              ] |
 | |  image  | [Price       ] [Purchased?] |
 | +---------+ [Buy Button               ] |
 +-----------------------------------------+
 
 */

protocol ProductCellDelegate: class {
    func requestBuyProduct(productId: ProductId)
}

class ProductCell: UITableViewCell {
    
    static let reuseId = "ProductCell"
    
    public weak var delegate: ProductCellDelegate?
    
    private var id: ProductId?
    var imgView = UIImageView()
    var localizedTitleLabel = UILabel()
    var localizedDescriptionLabel = UILabel()
    var localizedPriceLabel = UILabel()
    var purchasedLabel = UILabel()
    var buyButton = UIButton()
    
    var productInfo: ProductInfo? {
        didSet {
            guard let pInfo = productInfo else { return }
            
            imgView.image = UIImage(named: pInfo.imageName)
            
            localizedTitleLabel.text = pInfo.localizedTitle
            localizedDescriptionLabel.text = pInfo.localizedDescription
            localizedPriceLabel.text = String(pInfo.localizedPrice)
            
            purchasedLabel.text = pInfo.purchased ? "(purchased)" : "(available to purchase)"
            
            buyButton.backgroundColor = .systemGreen
            buyButton.setTitle("Buy", for: .normal)
            buyButton.layer.cornerRadius = 10
            buyButton.setTitleColor(.white, for: .normal)
            buyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            
            if pInfo.purchased { buyButton.isHidden = true }
            else { buyButton.addTarget(self, action: #selector(buyButtonTapped), for: .touchUpInside) }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) { fatalError("Storyboard not supported") }
    
    private func configureCell() {
        // You must add subviews to the *contentView*
        contentView.addSubview(imgView)
        contentView.addSubview(localizedTitleLabel)
        contentView.addSubview(localizedDescriptionLabel)
        contentView.addSubview(localizedPriceLabel)
        contentView.addSubview(purchasedLabel)
        contentView.addSubview(buyButton)
        
        localizedTitleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        localizedDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        localizedPriceLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        purchasedLabel.font = UIFont.preferredFont(forTextStyle: .footnote)

        translatesAutoresizingMaskIntoConstraints = false
        
        imgView.translatesAutoresizingMaskIntoConstraints = false
        localizedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        localizedDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        localizedPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        purchasedLabel.translatesAutoresizingMaskIntoConstraints = false
        buyButton.translatesAutoresizingMaskIntoConstraints = false

        let padding: CGFloat = 5
        
        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            imgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            imgView.heightAnchor.constraint(equalToConstant: 50),
            imgView.widthAnchor.constraint(equalToConstant: 50),
            
            localizedTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            localizedTitleLabel.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: padding),
            localizedTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            localizedPriceLabel.heightAnchor.constraint(equalToConstant: 20),
            
            localizedDescriptionLabel.topAnchor.constraint(equalTo: localizedTitleLabel.bottomAnchor, constant: padding),
            localizedDescriptionLabel.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: padding),
            localizedDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            localizedDescriptionLabel.heightAnchor.constraint(equalToConstant: 20),
            
            localizedPriceLabel.topAnchor.constraint(equalTo: localizedDescriptionLabel.bottomAnchor, constant: padding),
            localizedPriceLabel.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: padding),
            localizedPriceLabel.heightAnchor.constraint(equalToConstant: 20),
            localizedPriceLabel.widthAnchor.constraint(equalToConstant: 40),
            
            purchasedLabel.topAnchor.constraint(equalTo: localizedDescriptionLabel.bottomAnchor, constant: padding),
            purchasedLabel.leadingAnchor.constraint(equalTo: localizedPriceLabel.trailingAnchor, constant: padding),
            purchasedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            purchasedLabel.heightAnchor.constraint(equalToConstant: 20),
            
            buyButton.topAnchor.constraint(equalTo: localizedPriceLabel.bottomAnchor, constant: padding),
            buyButton.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: padding),
            buyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            buyButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    @objc func buyButtonTapped() {
        delegate?.requestBuyProduct(productId: productInfo!.id)
    }
}
