//
//  CanaryError.swift
//
//
//  Created by Mafalda on 5/31/24.
//

import Foundation

public enum CanaryError: Error
{
    case invalidStarbridgeConfig
    case invalidShadowConfig
    
    public var description: String
    {
        switch self {
            case .invalidStarbridgeConfig:
                return "Invalid Starbridge Config"
            case .invalidShadowConfig:
                return "Invalid Shadow Config"
        }
    }
}
