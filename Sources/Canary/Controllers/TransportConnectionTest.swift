//
//  TransportConnectionTest.swift
//  Canary
//
//  Created by Mafalda on 2/2/21.
//

import Foundation

import Chord
import Transport
import TransmissionAsync

class TransportConnectionTest
{
    var transportConnection: AsyncConnection
    var canaryString: String?
    
    init(transportConnection: AsyncConnection, canaryString: String?)
    {
        self.transportConnection = transportConnection
        self.canaryString = canaryString
    }
    
    func run() async -> Bool
    {
        uiLogger.debug("\n📣 Running transport connection test.")
        
        do
        {
            // Write an http request to the connection
            try await transportConnection.writeString(string: httpRequestString)
            
            do
            {
                // TODO: Use Straw here to make sure we get the full read and don't have a false failure
                
                // Try to read a response
                let response = try await transportConnection.read()
                
                // Be sure to close the connection
                await closeTransportConnection()
                
                // Check the response
                if response.string.contains("Yeah!\n")
                {
                    uiLogger.info("\n💕 🐥 It works! 🐥 💕")
                    return true
                }
                else
                {
                    uiLogger.error("\n🖤  We connected but the data did not match. 🖤")
                    uiLogger.error("\nHere's what we got back instead of what we expected: \(response.string)\n")
                    return false
                }
            }
            catch
            {
                uiLogger.info("🚫 We did not receive a response 🚫\n")
                return false
            }
        }
        catch
        {
            uiLogger.error("Error sending http request for TransportConnectionTest: \(error)")
            return false
        }
    }
    
    func closeTransportConnection() async
    {
        do
        {
            // Be sure to close the connection
            try await transportConnection.close()
        }
        catch
        {
            uiLogger.warning("Received an error while trying to close a transport connection \(error)")
        }
    }
}
