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

import NetUtils

struct CanaryTest
{
    var canaryTestQueue = DispatchQueue(label: "CanaryTests")
    var configDirPath: String
    var savePath: String?
    var testCount: Int = 1
    var interface: String?
    var debugPrints: Bool
    var runWebTests: Bool
    
    /// launch AdversaryLabClient to capture our test traffic, and run a connection test.
    ///  a csv file and song data (zipped) are saved with the test results.
    func begin() async
    {
        print("\n Attempting to run tests...\n")
        
        // Make sure we have everything we need first
        guard checkSetup() else { return }
        
        
        var interfaceName: String
        
        if interface != nil
        {
            // Use the user provided interface name
            interfaceName = interface!
            print("Running tests using the user selected interface \(interfaceName)")
            uiLogger.info("User selected interface name: \(interfaceName)\n")
        }
        else
        {
            // Try to guess the interface, if we cannot then give up
            guard let name = guessUserInterface() else
            {
                uiLogger.error("Canary was unable to identify the correct interface and one was not previously specified. Canary testing has been cancelled.\n")
                return
            }
            
            
            interfaceName = name
            
            print("\nCanary has selected the most likely interface name. If Canary fails to capture data, it may be because this is not the correct interface. Please try running the program again using the interface flag and one of the other listed interfaces.\n")
            uiLogger.info("Canary selected interface name: \(interfaceName)\n")
        }
        
        await runAllTests(interfaceName: interfaceName, runWebTests: runWebTests)
    }
    
    func runAllTests(interfaceName: String, runWebTests: Bool) async
    {
        for i in 1...testCount
        {
            uiLogger.info("\n***************************\nRunning test batch \(i) of \(testCount)\n***************************\n")
            
            for transport in testingTransports
            {
                uiLogger.log(level: .info, "\n 🧪 Starting test for \(transport.name) 🧪")
                await TestController.sharedInstance.test(transport: transport, interface: interfaceName, debugPrints: debugPrints)
            }
            
            if (runWebTests)
            {
                for webTest in allWebTests
                {
                    uiLogger.info("\n 🧪 Starting web test for \(webTest.website) 🧪")
                    print("\n 🧪 Starting web test for \(webTest.website) 🧪")
                    TestController.sharedInstance.test(webTest: webTest, interface: interfaceName, debugPrints: debugPrints)
                }
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
        
        let filteredInterfaces = allInterfaces.filter
        {
            (thisInterface: Interface) -> Bool in
            
            guard let thisAddress = thisInterface.address
            else { return false }
            
            guard thisAddress != "127.0.0.1"
            else { return false }
            
            guard thisAddress != "::1"
            else { return false }
            
            guard thisAddress != "fe80::1"
            else { return false }
            
            guard !thisAddress.starts(with: "fe80")
            else { return false }
            
            return true
        }
        
        print("Filtered interfaces:")
        for shortListInterface in filteredInterfaces { print("\(shortListInterface.name): \(shortListInterface.debugDescription)")}
        
        // Return the first interface that begins with the letter e
        // Note: this is just a best guess based on what we understand to be a common scenario
        // The user should use the interface flag if they have something different
        
        if let ipv4Interface = filteredInterfaces.first(where: {$0.family == .ipv4})
        {
            return ipv4Interface.name
        }
        else
        {
            guard let bestGuess = filteredInterfaces.firstIndex(where: { $0.name.hasPrefix("e") })
            else
            {
                print("\nWe were unable to identify a likely interface name. Please try running the program again using the interface flag and one of the other listed interfaces.\n")
                return nil
            }
            
            return allInterfaces[bestGuess].name
        }
    }
    
    func checkSetup() -> Bool
    {
        uiLogger.info("\n🔍 Checking your setup...\n")
        // Does the Resources Directory Exist?
        configDirectoryPath = configDirPath
        uiLogger.info("\n✔️ Config directory: \(configDirectoryPath)\n")
        guard FileManager.default.fileExists(atPath: configDirectoryPath)
        else
        {
            uiLogger.error("\n‼️ Resource directory does not exist at \(configDirectoryPath).\n")
            return false
        }
        
        if (savePath != nil)
        {
            saveDirectoryPath = savePath!
            
            // Does the save directory exist?
            guard FileManager.default.fileExists(atPath: saveDirectoryPath)
            else
            {
                uiLogger.error("\n‼️ The selected save directory does not exist at \(saveDirectoryPath).\n")
                return false
            }
            
            uiLogger.info("\n✔️ User selected save directory: \(saveDirectoryPath)\n")
        }

        guard prepareTransports()
        else { return false }

        uiLogger.info("✔️ Check setup completed")
        return true
    }
    
    func prepareTransports() -> Bool
    {
        testingTransports.removeAll()
        
        // Check the config directory for config files
        do
        {
            let filenames = try FileManager.default.contentsOfDirectory(atPath: configDirectoryPath)
            
            for thisFilename in filenames
            {
                for thisTransportName in possibleTransportNames
                {
                    // Add the names of each config file that contains a valid transport name to allTransports
                    if (thisFilename.lowercased().contains(thisTransportName.lowercased()))
                    {
                        let configPath = configDirectoryPath.appending("/\(thisFilename)")
                        let configURL = URL(fileURLWithPath: thisFilename)
                        let transportTestName = configURL.deletingPathExtension().lastPathComponent
                        
                        if let newTransport = CanaryTransport(name: transportTestName, typeString: thisTransportName, configPath: configPath)
                        {
                            testingTransports.append(newTransport)
                            uiLogger.info("\n✔️ \(newTransport.name) test is ready\n")
                        }
                        else
                        {
                            uiLogger.error("⚠️ Failed to create a new transport using the provided config at \(configPath)")
                        }
                    }
                }
            }
            
            guard !testingTransports.isEmpty
            else
            {
                uiLogger.error("‼️ There were no valid transport configs in the provided directory. Ending test.\nConfig Directory: \(configDirectoryPath)")
                return false
            }
            
            return true
        }
        catch
        {
            uiLogger.error("‼️ Unable to retrieve the contents of \(configDirectoryPath): \(error)")
            return false
        }
    }
}


