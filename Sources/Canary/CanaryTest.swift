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

import ArgumentParser
import Foundation

import Gardener
import NetUtils
import Transmission

struct CanaryTest//: ParsableCommand
{
    var canaryTestQueue = DispatchQueue(label: "CanaryTests")
    var serverIP: String
    var resourceDirPath: String
    var savePath: String?
    var testCount: Int = 1
    var interface: String?
    var debugPrints: Bool
    
    /// launch AdversaryLabClient to capture our test traffic, and run a connection test.
    ///  a csv file and song data (zipped) are saved with the test results.
    func begin(runAsync: Bool)
    {
        print("\n Attempting to run tests...\n")
        
        resourcesDirectoryPath = resourceDirPath
        uiLogger.info("\nUser selected resources directory: \(resourcesDirectoryPath)\n")
        print("\nUser selected resources directory: \(resourcesDirectoryPath)\n")
        
        if (savePath != nil)
        {
            saveDirectoryPath = savePath!
            uiLogger.info("\nUser selected save directory: \(saveDirectoryPath)\n")
            print(" * \nUser selected save directory: \(saveDirectoryPath)\n")
        }
        
        // Make sure we have everything we need first
        
        guard checkSetup() else { return }
        print("Returned from checkSetup()")
        
        
        var interfaceName: String
        
        if interface != nil
        {
            // Use the user provided interface name
            interfaceName = interface!
        }
        else
        {
            // Try to guess the interface, if we cannot then give up
            guard let name = guessUserInterface()
            else { return }
            
            interfaceName = name
        }
        
        uiLogger.info("Selected an interface for running test: \(interfaceName)\n")
        
        if runAsync
        {
            canaryTestQueue.async {
                runAllTests(interfaceName: interfaceName)
            }
        }
        else
        {
            runAllTests(interfaceName: interfaceName)
        }
    }
    
    func runAllTests(interfaceName: String)
    {
        for i in 1...testCount
        {
            uiLogger.info("\n***************************\nRunning test batch \(i) of \(testCount)\n***************************\n")
            print("\n***************************\nRunning test batch \(i) of \(testCount)\n***************************")
            
            for transport in allTransports
            {
                uiLogger.log(level: .info, "\n 🧪 Starting test for \(transport.name) 🧪")
                print("\n * 🧪 Starting test for \(transport.name) 🧪\n")
                TestController.sharedInstance.test(name: transport.name, serverIPString: serverIP, port: transport.port, interface: interfaceName, webAddress: nil, debugPrints: debugPrints)
            }
            
            for webTest in allWebTests
            {
                uiLogger.info("\n 🧪 Starting web test for \(webTest.website) 🧪")
                print("\n 🧪 Starting web test for \(webTest.website) 🧪")
                TestController.sharedInstance.test(name: webTest.name, serverIPString: serverIP, port: webTest.port, interface: interfaceName, webAddress: webTest.website, debugPrints: debugPrints)
            }
            
            // This directory contains our test results.
            zipResults()
        }
    }
    
    func guessUserInterface() -> String?
    {
        var allInterfaces = Interface.allInterfaces()
        
        // Get interfaces sorted by name
        allInterfaces.sort(by: {
            (interfaceA, interfaceB) -> Bool in
            
            return interfaceA.name < interfaceB.name
        })
        
        print("\nUser did not indicate a preferred interface. Printing all available interfaces.")
        for interface in allInterfaces { print("\(interface.name): \(interface.debugDescription)")}
        
        let filteredInterfaces = allInterfaces.filter
        {
            (thisInterface: Interface) -> Bool in
            
            return thisInterface.address != nil
        }
        
        print("Filtered interfaces:")
        for shortListInterface in filteredInterfaces { print("\(shortListInterface.name): \(shortListInterface.debugDescription)")}
        
        // Return the first interface that begins with the letter e
        // Note: this is just a best guess based on what we understand to be a common scenario
        // The user should use the interface flag if they have something different
        guard let bestGuess = filteredInterfaces.firstIndex(where: { $0.name.hasPrefix("e") })
        else
        {
            print("\nWe were unable to identify a likely interface name. Please try running the program again using the interface flag and one of the other listed interfaces.\n")
            return nil
        }
        
        print("\nWe will try using the \(allInterfaces[bestGuess].name) interface. If Canary fails to capture data, it may be because this is not the correct interface. Please try running the program again using the interface flag and one of the other listed interfaces.\n")
        
        return allInterfaces[bestGuess].name
    }
    
    func checkSetup() -> Bool
    {
        print("Check setup called")
        // Does the Resources Directory Exist
        guard FileManager.default.fileExists(atPath: resourcesDirectoryPath)
        else
        {
            uiLogger.info("\nResource directory does not exist at \(resourcesDirectoryPath).\n")
            print("Resource directory does not exist at \(resourcesDirectoryPath).")
            return false
        }
        
        // Does it contain the files we need
        // One config for every transport being tested
        for transport in allTransports
        {
            switch transport
            {
            case shadowsocks:
                guard FileManager.default.fileExists(atPath:"\(resourcesDirectoryPath)/\(shSocksFilePath)")
                else
                {
                    uiLogger.info("Shadowsocks config not found at \(resourcesDirectoryPath)/\(shSocksFilePath)")
                    print("Shadowsocks config not found at \(resourcesDirectoryPath)/\(shSocksFilePath)")
                    return false
                }
            case replicant:
                guard FileManager.default.fileExists(atPath:"\(resourcesDirectoryPath)/\(replicantFilePath)")
                else
                {
                    uiLogger.info("Replicant config not found at \(resourcesDirectoryPath)/\(replicantFilePath)")
                    print("Replicant config not found at \(resourcesDirectoryPath)/\(replicantFilePath)")
                    return false
                }
            default:
                uiLogger.info("\nTried to test a transport that has no config file. Transport name: \(transport.name)\n")
                print("Tried to test a transport that has no config file. Transport name: \(transport.name)")
                return false
            }
        }
        
        // Is the transport server running
        if !allTransports.isEmpty
        {            
            guard let _ = Transmission.TransmissionConnection(host: serverIP, port: Int(string: allTransports[0].port), type: .tcp)
            else
            {
                uiLogger.info("\nFailed to connect to the transport server.\nIP: \(serverIP)\nport: \(allTransports[0].port)")
                print("\nFailed to connect to the transport server.\nIP: \(serverIP)\nport: \(allTransports[0].port)")
                return false
            }
        }
        
        print("Check setup completed")
        return true
    }
}


