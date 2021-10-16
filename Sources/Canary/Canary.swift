import Logging

var uiLogger: Logger!
var runningTests = false

public class Canary
{
    var chirp: CanaryTest

    public required init(serverIP: String, configPath: String, logger: Logger, timesToRun: Int = 1, interface: String?)
    {
        uiLogger = logger
        chirp = CanaryTest(serverIP: serverIP, resourceDirPath: configPath, testCount: timesToRun, interface: interface)
    }
    
    func runTest()
    {
        chirp.begin()
    }
}
