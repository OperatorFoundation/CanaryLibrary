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
        guard let completion = self.connectionCompletion
        else
        {
            print("Canary.TransportController: Unable to handle new state: \(newState), our TransportController.connectionCompletion handler is nil.")
            return
        }
        
        switch newState
        {
            case .ready:
                completion(connection)
                self.connectionCompletion = nil
            case .cancelled:
                completion(nil)
                self.connectionCompletion = nil
            case .failed(let error):
                print("Canary.TransportController: Transport connection failed: \(error)")
                completion(nil)
                self.connectionCompletion = nil
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
                    uiLogger.error("Canary.TransportController: Failed to create a ShadowSocks connection.")
                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                }
                
            default:
                uiLogger.error("Canary.TransportController: Invalid ShadowSocks config.")
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
                        print("Canary.TransportController: Failed to create a Replicant connection.")
                        handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                        return
                    }
                    
                    connection = replicantConnection
                    replicantConnection.stateUpdateHandler = self.handleStateUpdate
                    replicantConnection.start(queue: transportQueue)
                }
                catch
                {
                    print("Canary.TransportController: Failed to create a Replicant connection: \(error)")
                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                }
                
            default:
                uiLogger.error("Canary.TransportController: Invalid Replicant config.")
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
                    uiLogger.error("Canary.TransportController: Failed to create a Starbridge connection: \(error)")
                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
                }
                
            default:
                uiLogger.error("Canary.TransportController: Invalid Starbridge config.")
                return
        }
    }
}
