//
//  IAPUtils.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 04/07/2020.
//

import UIKit

/// Misc utility methods used by IAPHelper.
public class IAPUtils {
    
    internal class func showMessage(msg: String, title: String) {
        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        if let vc = IAPUtils.currentViewController() {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    @available(iOS 13, *)
    fileprivate class func currentViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene.delegate as? SceneDelegate,
              let window = sceneDelegate.window,
              let rootVC = window.rootViewController else { return nil }
            
        return rootVC is UINavigationController ? (rootVC as! UINavigationController).visibleViewController : rootVC
    }
}
