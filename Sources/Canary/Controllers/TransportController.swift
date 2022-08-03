//
//  TransportController.swift
//  Canary
//
//  Created by Mafalda on 1/27/21.
//

import Foundation
import Logging

import Net
import ReplicantSwift
import ShadowSwift
import Starbridge
import Transport

class TransportController
{
    let transportQueue = DispatchQueue(label: "TransportQueue")
    var transport: Transport
    var connectionCompletion: ((Connection?) -> Void)?
    var connection: Connection?
    
    init(transport: Transport, log: Logger)
    {
        self.transport = transport
    }
            
    func startTransport(completionHandler: @escaping (Connection?) -> Void)
    {
        connectionCompletion = completionHandler
        
        switch transport.type
        {
            case .replicant:
                launchReplicant()
            case .shadowsocks:
                launchShadow()
            case .starbridge:
                launchStarbridge()
        }
    }
    
    func handleStateUpdate(_ newState: NWConnection.State)
    {
        guard let completion = connectionCompletion
        else
        {
            print("Unable to establish transport connection, our completion handler is nil.")
            return
        }
        
        switch newState
        {
            case .ready:
                completion(connection)
            case .cancelled:
                completion(nil)
            case .failed(let error):
                print("Transport connection failed: \(error)")
                completion(nil)
            default:
                return
        }
    }
    
    func launchShadow()
    {
        switch transport.config
        {
            case .shadowsocksConfig(let shadowConfig):
                let shadowFactory = ShadowConnectionFactory(config: shadowConfig, logger: uiLogger)
                                
                if var shadowConnection = shadowFactory.connect(using: .tcp)
                {
                    connection = shadowConnection
                    shadowConnection.stateUpdateHandler = self.handleStateUpdate
                    shadowConnection.start(queue: transportQueue)
                }
                else
                {
                    uiLogger.error("Failed to create a ShadowSocks connection.")
                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                }
                
            default:
                uiLogger.error("Invalid ShadowSocks config.")
                return
        }
    }
    
    func launchReplicant()
    {
        switch transport.config
        {
            case .replicantConfig(let replicantConfig):
                let replicant = Replicant(logger: uiLogger)
                guard var replicantConnection = try? replicant.connect(host: replicantConfig.serverIP, port: Int(replicantConfig.port), config: replicantConfig) as? Connection
                else
                {
                    print("Failed to create a Replicant connection.")
                    return
                }

                connection = replicantConnection
                replicantConnection.stateUpdateHandler = self.handleStateUpdate
                replicantConnection.start(queue: transportQueue)
                
            default:
                uiLogger.error("Invalid Replicant config.")
                return
        }
    }
    
    func launchStarbridge()
    {
        switch transport.config
        {
            case .starbridgeConfig(let starbridgeConfig):
                let starburstConfig = StarburstConfig.SMTPClient
                let starbridge = Starbridge(logger: uiLogger, config: starburstConfig)
                guard let maybeStarbridgeConnection = try? starbridge.connect(config: starbridgeConfig)
                else
                {
                    uiLogger.error("Failed to create a Starbridge connection.")
                    return
                }
                
                guard var starbridgeConnection = maybeStarbridgeConnection as? Connection else {
                    uiLogger.error("Starbridge connection was the wrong type: \(type(of: maybeStarbridgeConnection))")
                    return
                }
                
                connection = starbridgeConnection
                starbridgeConnection.stateUpdateHandler = self.handleStateUpdate
                starbridgeConnection.start(queue: transportQueue)

            default:
                uiLogger.error("Invalid Starbridge config.")
                return
        }
    }
}
