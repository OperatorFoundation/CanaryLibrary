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
import TransmissionAsync

class TransportController
{
    var transport: CanaryTransport
    
    init(transport: CanaryTransport, log: Logger)
    {
        self.transport = transport
    }
            
    func startTransport() async throws -> AsyncConnection
    {
        switch transport.type
        {
            case .shadowsocks:
                try await launchShadow()
            case .starbridge:
                try await launchStarbridge()
        }
    }
    
    func launchShadow() async throws -> AsyncConnection
    {
        switch transport.config
        {
            case .shadowConfig(let shadowConfig):
                let shadowClientConnection = try await AsyncDarkstarClientConnection(shadowConfig.serverIP, Int(shadowConfig.serverPort), shadowConfig, uiLogger)
                return shadowClientConnection
                
            default:
                throw CanaryError.invalidShadowConfig
        }
    }
    
    func launchStarbridge() async throws -> AsyncConnection
    {
        switch transport.config
        {
            case .starbridgeConfig(let starbridgeConfig):
                let starbridge = Starbridge(logger: uiLogger)
                let starbridgeConnection = try await starbridge.connect(config: starbridgeConfig)
                return starbridgeConnection
                
            default:
                throw CanaryError.invalidStarbridgeConfig
        }
    }
    
//    let transportQueue = DispatchQueue(label: "TransportQueue")
//    var transport: CanaryTransport
//    var connectionCompletion: ((Transport.Connection?) -> Void)?
//    var connection: Transport.Connection?
//    
//    init(transport: CanaryTransport, log: Logger)
//    {
//        self.transport = transport
//    }
//            
//    func startTransport(completionHandler: @escaping (Transport.Connection?) -> Void)
//    {
//        self.connectionCompletion = completionHandler
//        
//        switch transport.type
//        {
//            case .shadowsocks:
//                launchShadow()
//            case .starbridge:
//                launchStarbridge()
//        }
//    }
//    
//    func handleStateUpdate(_ newState: NWConnection.State)
//    {
//        guard let completion = self.connectionCompletion
//        else
//        {
//            print("Canary.TransportController: Unable to handle new state: \(newState), our TransportController.connectionCompletion handler is nil.")
//            return
//        }
//        
//        switch newState
//        {
//            case .ready:
//                completion(connection)
//                self.connectionCompletion = nil
//            case .cancelled:
//                completion(nil)
//                self.connectionCompletion = nil
//            case .failed(let error):
//                print("Canary.TransportController: Transport connection failed: \(error)")
//                completion(nil)
//                self.connectionCompletion = nil
//            default:
//                return
//        }
//    }
//    
//    func launchShadow()
//    {
//        switch transport.config
//        {
//            case .shadowConfig(let shadowConfig):
//                let shadowFactory = ShadowConnectionFactory(config: shadowConfig, logger: uiLogger)
//                                    
//                if var shadowConnection = shadowFactory.connect(using: .tcp)
//                {
//                    connection = shadowConnection
//                    shadowConnection.stateUpdateHandler = self.handleStateUpdate
//                    shadowConnection.start(queue: transportQueue)
//                }
//                else
//                {
//                    uiLogger.error("Canary.TransportController: Failed to create a ShadowSocks connection.")
//                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
//                }
//                
//            default:
//                uiLogger.error("Canary.TransportController: Invalid ShadowSocks config.")
//                return
//        }
//    }
//    
//    func launchStarbridge()
//    {
//        switch transport.config
//        {
//            case .starbridgeConfig(let starbridgeConfig):
//                let starbridge = Starbridge(logger: uiLogger)
//                
//                do
//                {
//                    let starbridgeConnection = try starbridge.connect(config: starbridgeConfig)
//                    let starbridgeTransportConnection = TransmissionTransport.TransmissionToTransportConnection({return starbridgeConnection})
//                    
//                    self.connection = starbridgeTransportConnection
//                    starbridgeTransportConnection.stateUpdateHandler = self.handleStateUpdate
//                    starbridgeTransportConnection.start(queue: transportQueue)
//                }
//                catch
//                {
//                    uiLogger.error("Canary.TransportController: Failed to create a Starbridge connection: \(error)")
//                    handleStateUpdate(.failed(NWError.posix(.ECONNREFUSED)))
//                }
//                
//            default:
//                uiLogger.error("Canary.TransportController: Invalid Starbridge config.")
//                return
//        }
//    }
}
