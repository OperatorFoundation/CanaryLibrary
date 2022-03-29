//
//  TransportController.swift
//  Canary
//
//  Created by Mafalda on 1/27/21.
//

import Foundation
import Logging

import Net
import ReplicantSwiftClient
import ReplicantSwift
import ShadowSwift
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
                
                print("Shadow config server IP: \(shadowConfig.serverIP)")
                
                guard var shadowConnection = shadowFactory.connect(using: .tcp)
                else
                {
                    uiLogger.error("Failed to create a ShadowSocks connection.")
                    return
                }
                
                connection = shadowConnection
                shadowConnection.stateUpdateHandler = self.handleStateUpdate
                shadowConnection.start(queue: transportQueue)
                
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
                let replicantFactory = ReplicantConnectionFactory(config: replicantConfig, log: uiLogger)

                guard var replicantConnection = replicantFactory.connect(using: .tcp)
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
}
