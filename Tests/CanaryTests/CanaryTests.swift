import Logging
import XCTest

@testable import Canary

final class CanaryTests: XCTestCase
{
    
    /// This is an example of how to use this library's API with the minimum required arguments
    func testQuickSetupCanary()
    {
        let configDirectoryPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("CanaryConfigs", isDirectory: true).path
        
        let logger = Logger(label: "CanaryExample")
        
        let canary = Canary(configPath: configDirectoryPath, logger: logger)
        
        canary.runTest()
    }

}
