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
import TransmissionTypes
import TransmissionTransport

class TransportController
{
    let transportQueue = DispatchQueue(label: "TransportQueue")
    var transport: CanaryTransport
    var connectionCompletion: ((Transport.Connection?) -> Void)?
    var connection: Transport.Connection?
    
    init(transport: CanaryTransport, log: Logger)
    {
        self.transport = transport
    }
            
    func startTransport(completionHandler: @escaping (Transport.Connection?) -> Void)
    {
        self.connectionCompletion = completionHandler
        
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
                
                do
                {
                    guard var replicantConnection = try replicant.connect(host: replicantConfig.serverIP, port: Int(replicantConfig.port), config: replicantConfig) as? Transport.Connection else
                    {
                        print("Failed to create a Replicant connection.")
                        handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                        return
                    }
                    
                    connection = replicantConnection
                    replicantConnection.stateUpdateHandler = self.handleStateUpdate
                    replicantConnection.start(queue: transportQueue)
                }
                catch
                {
                    print("Failed to create a Replicant connection: \(error)")
                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                }
                
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
                
                do
                {
                    let starbridgeConnection = try starbridge.connect(config: starbridgeConfig)
                    let starbridgeTransportConnection = TransmissionTransport.TransmissionToTransportConnection({return starbridgeConnection})
                    
                    self.connection = starbridgeTransportConnection
                    starbridgeTransportConnection.stateUpdateHandler = self.handleStateUpdate
                    starbridgeTransportConnection.start(queue: transportQueue)
                }
                catch
                {
                    uiLogger.error("Failed to create a Starbridge connection: \(error)")
                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                }
                
            default:
                uiLogger.error("Invalid Starbridge config.")
                return
        }
    }
}
