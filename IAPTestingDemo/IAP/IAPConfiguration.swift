//
//  IAPConfiguration.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 24/06/2020.
//

import UIKit

public struct IAPConfiguration {
    
    public static func read(filename: String, ext: String) -> Result<IAPConfigurationModel, IAPConfigurationError> {
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            return .failure(.cantFindInBundle)
        }

        guard let data = try? Data(contentsOf: url) else {
            return .failure(.cantReadData)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        guard let configuration = try? decoder.decode(IAPConfigurationModel.self, from: data) else {
            return .failure(.cantDecode)
        }
        
        return .success(configuration)
    }
}
