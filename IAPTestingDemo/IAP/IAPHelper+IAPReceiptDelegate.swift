//
//  IAPHelper+IAPReceiptDelegate.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 13/07/2020.
//

extension IAPHelper: IAPReceiptDelegate {
    
    /// Make a request to send an IAP-related notification.
    /// - Parameter notification: The required notification.
    public func requestSendNotification(notification: IAPNotification) {
        sendNotification(notification: notification)
    }
}
