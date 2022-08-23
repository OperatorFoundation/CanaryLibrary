import Logging

var uiLogger: Logger!

public class Canary
{
    private var chirp: CanaryTest

    public required init(configPath: String, savePath: String? = nil, logger: Logger, timesToRun: Int = 1, interface: String? = nil, debugPrints: Bool = false, runWebTests: Bool = false)
    {
        uiLogger = logger
        uiLogger.logLevel = .info
        chirp = CanaryTest(configDirPath: configPath, savePath: savePath, testCount: timesToRun, interface: interface, debugPrints: debugPrints, runWebTests: runWebTests)
    }
    
    public func runTest(runAsync: Bool = true)
    {
        chirp.begin(runAsync: runAsync)
    }
}
