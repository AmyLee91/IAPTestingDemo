//
//  IAPReceiptDelegate.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 06/07/2020.
//

import Foundation

public protocol IAPReceiptDelegate: class {
    func requestSendNotification(notification: IAPNotification)
}

