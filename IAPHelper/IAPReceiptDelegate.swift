//
//  IAPReceiptDelegate.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 06/07/2020.
//

import Foundation

/// IAPReceiptDelegate
public protocol IAPReceiptDelegate: class {
    func requestSendNotification(notification: IAPNotification)
}

