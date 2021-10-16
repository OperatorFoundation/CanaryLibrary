import Logging

var uiLogger: Logger!

public class Canary
{
    private var chirp: CanaryTest

    public required init(serverIP: String, configPath: String, logger: Logger, timesToRun: Int = 1, interface: String? = nil)
    {
        uiLogger = logger
        chirp = CanaryTest(serverIP: serverIP, resourceDirPath: configPath, testCount: timesToRun, interface: interface)
    }
    
    public func runTest()
    {
        chirp.begin()
    }
}
