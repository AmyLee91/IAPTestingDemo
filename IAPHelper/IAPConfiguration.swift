//
//  IAPConfiguration.swift
//  IAPHelper
//
//  Created by Russell Archer on 24/06/2020.
//

import UIKit

/// Provides static methods for reading .storekit configuration files.
public struct IAPConfiguration {

    /// Read the .storekit file appropriate for the build and extract the configuration data (which includes the list of Product IDs).
    /// - Parameters:
    ///   - filename:   The configuration file name
    ///   - ext:        The configuration file extension
    /// - Returns:      Returns a Result where the .success value is a configuration model containing data read from the .storekit file.
    ///                 The .failure value is a notification indicating the reason for the failure.
    public static func read(filename: String, ext: String) -> Result<IAPConfigurationModel, IAPNotification> {
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else { return .failure(.configurationCantFindInBundle) }
        guard let data = try? Data(contentsOf: url) else { return .failure(.configurationCantReadData) }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        guard let configuration = try? decoder.decode(IAPConfigurationModel.self, from: data) else { return .failure(.configurationCantDecode) }
        
        return .success(configuration)
    }
}
