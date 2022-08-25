//
//  TransportConnectionTest.swift
//  Canary
//
//  Created by Mafalda on 2/2/21.
//

import Foundation

import Chord
import Transport

#if (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
import Network
#else
import NetworkLinux
#endif

class TransportConnectionTest
{
    var transportConnection: Connection
    var canaryString: String?
    var readBuffer = Data()
    
    init(transportConnection: Connection, canaryString: String?)
    {
        self.transportConnection = transportConnection
        self.canaryString = canaryString
    }
    
    func send(completionHandler: @escaping (NWError?) -> Void)
    {
        transportConnection.send(content: Data(string: httpRequestString), contentContext: .defaultMessage, isComplete: true, completion: NWConnection.SendCompletion.contentProcessed(completionHandler))
    }
    
    func read(completionHandler: @escaping (Data?) -> Void)
    {
        transportConnection.receive(minimumIncompleteLength: 1, maximumLength: 1500)
        {
            (maybeData,_,_, maybeError) in
            
            if let error = maybeError
            {
                uiLogger.info("\nError reading data for transport connection: \(error)\n")
                completionHandler(self.readBuffer)
                return
            }
            
            if let data = maybeData
            {
                self.readBuffer.append(data)
                
                if self.readBuffer.string.contains("Yeah!\n")
                {
                    completionHandler(self.readBuffer)
                    return
                }
                else
                {
                    self.read(completionHandler: completionHandler)
                }
            }
            else
            {
                completionHandler(self.readBuffer)
                return
            }
        }
    }
    
    func run() -> Bool
    {
        uiLogger.debug("\n📣 Running transport connection test.")
        
        let maybeError = Synchronizer.sync(self.send)
        if let error = maybeError
        {
            uiLogger.error("Error sending http request for TransportConnectionTest: \(error)")
            return false
        }
        
        guard let response = Synchronizer.sync(read) else
        {
            uiLogger.info("🚫 We did not receive a response 🚫\n")
            return false
        }
        
        if response.string.contains("Yeah!\n")
        {
            uiLogger.info("\n💕 🐥 It works! 🐥 💕")
            transportConnection.cancel()
            return true
        }
        else
        {
            uiLogger.error("\n🖤  We connected but the data did not match. 🖤")
            transportConnection.cancel()
            uiLogger.error("\nHere's what we got back instead of what we expected: \(response.string)\n")
            return false
        }
    }
}
