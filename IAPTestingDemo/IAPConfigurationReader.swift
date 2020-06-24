//
//  IAPConfigurationReader.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 24/06/2020.
//

import UIKit

struct IAPConfigurationModel: Decodable {
    let products: [IAPConfigurationModelProducts]?
    let settings: IAPConfigurationModelSettings?
    let subscriptionGroups: [String]?  // TODO: Placeholder as they're not Strings
    let version: IAPConfigurationModelVersion?
}

struct IAPConfigurationModelProducts: Decodable {
    let displayPrice: String?
    let familyShareable: Bool?
    let internalID: String?
    let localizations: [IAPConfigurationModelLocalizations]?
    let productID: String?
    let referenceName: String?
    let type: String?
}

struct IAPConfigurationModelLocalizations: Decodable {
    let description: String?
    let displayName: String?
    let locale: String?
}

struct IAPConfigurationModelSettings: Decodable {
    let _askToBuyEnabled: Bool?
}

struct IAPConfigurationModelVersion: Decodable {
    let major: Int?
    let minor: Int?
}

enum IAPConfigurationError: Error {
    case cantFindInBundle
    case cantReadData
    case cantDecode
}

// MARK:- IAPConfigurationReader

class IAPConfigurationReader {
    
    class func read(filename: String, ext: String) -> Result<IAPConfigurationModel, IAPConfigurationError> {
        
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
