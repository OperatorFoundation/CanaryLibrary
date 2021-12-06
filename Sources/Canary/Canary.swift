import Logging

var uiLogger: Logger!

public class Canary
{
    private var chirp: CanaryTest

    public required init(serverIP: String, configPath: String, savePath: String? = nil, logger: Logger, timesToRun: Int = 1, interface: String? = nil, debugPrints: Bool = false)
    {
        uiLogger = logger
        chirp = CanaryTest(serverIP: serverIP, resourceDirPath: configPath, savePath: savePath, testCount: timesToRun, interface: interface, debugPrints: debugPrints)
    }
    
    public func runTest()
    {
        chirp.begin()
    }
}
