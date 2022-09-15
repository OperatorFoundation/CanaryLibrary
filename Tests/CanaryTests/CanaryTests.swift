import Logging
import XCTest

import Gardener

@testable import Canary

final class CanaryTests: XCTestCase
{
    
    /// This is an example of how to use this library's API with the minimum required arguments
    func testQuickSetupCanary()
    {
        let godot = XCTestExpectation(description: "Never arrives")
        
        let configDirectoryPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/CanaryConfigs", isDirectory: true).path
        
        let logger = Logger(label: "CanaryExample")
        
        let canary = Canary(configPath: configDirectoryPath, logger: logger)
        
        canary.runTest(runAsync: true)
        
        wait(for: [godot], timeout: 30)
    }
    
    func testSSHTunnel()
    {
        let username = "" // username for your tunnel server (think standard ssh)
        let host = "" // The tunnel server (maybe your droplet)
        let localListenPort = 7171 // An open port on your local machine
        let remoteConnectHost = "localhost" // The ultimate destination server
        let remoteConnectPort = 80
        
        guard let sshTunnel = SSHLocalTunnel(username: username, host: host, tunnelLocalListenPort: localListenPort, tunnelRemoteConnectHost: remoteConnectHost, tunnelRemoteConnectPort: remoteConnectPort) else
        {
            XCTFail()
            return
        }

        guard let url = URL(string: "http://localhost:\(localListenPort)") else
        {
            XCTFail()
            return
        }
        
        do
        {
            let result = try String(contentsOf: url)
            
            print("testSSHTunnel url contents: \(result)")
        }
        catch
        {
            print("Failed to fetch url contents: \(error)")
            XCTFail()
            return
        }
        
        sshTunnel.stop()
    }

}
