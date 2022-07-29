//
//  Transport.swift
//  Canary
//
//  Created by Mafalda on 9/5/19.
//  MIT License
//
//  Copyright (c) 2020 Operator Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import ReplicantSwift
import ShadowSwift
import Starbridge

struct Transport
{
    let name: String
    let type: TransportType
    let configPath: String
    let config: TransportConfig
    let serverIP: String
    let port: UInt16
    
    init?(name: String, typeString: String, configPath: String)
    {
        self.name = name
        self.configPath = configPath
        
        guard (FileManager.default.fileExists(atPath: configPath))
        else
        {
            uiLogger.error("Config file for \(name) does not exist at \(configPath)")
            return nil
        }

        guard let newTransportType = TransportType(rawValue: typeString.lowercased())
        else
        {
            uiLogger.error("\(name) cannot be identified with a supported transport.")
            return nil
        }
        
        self.type = newTransportType
        
        switch newTransportType
        {
            case .replicant:
                guard let replicantConfig = ReplicantClientConfig(withConfigAtPath: configPath)
                else
                {
                    uiLogger.error("Failed to create a Replicant config.")
                    return nil
                }
                
                self.config = TransportConfig.replicantConfig(replicantConfig)
                self.serverIP = replicantConfig.serverIP
                self.port = replicantConfig.port
                
            case .shadowsocks:
                guard let shadowConfig = ShadowConfig(path: configPath)
                else
                {
                    uiLogger.error("\n Unable to parse the ShadowSocks config at \(configPath)")
                    return nil
                }
                
                self.config = TransportConfig.shadowsocksConfig(shadowConfig)
                self.serverIP = shadowConfig.serverIP
                self.port = shadowConfig.port
                
            case .starbridge:
                guard let starbridgeConfig = StarbridgeClientConfig(withConfigAtPath: configPath)
                else
                {
                    uiLogger.error("Failed to create a Starbridge config")
                    return nil
                }
                
                self.config = TransportConfig.starbridgeConfig(starbridgeConfig)
                self.serverIP = starbridgeConfig.replicantConfig.serverIP
                self.port = starbridgeConfig.replicantConfig.port
        }
    }
}

enum TransportType: String
{
    case replicant = "replicant"
    case shadowsocks = "shadowsocks"
    case starbridge = "starbridge"
}

enum TransportConfig
{
    case replicantConfig(ReplicantClientConfig)
    case shadowsocksConfig(ShadowConfig)
    case starbridgeConfig(StarbridgeClientConfig)
}
