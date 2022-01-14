import Logging

var uiLogger: Logger!

public class Canary
{
    private var chirp: CanaryTest

    public required init(serverIP: String, configPath: String, savePath: String? = nil, logger: Logger, timesToRun: Int = 1, interface: String? = nil, debugPrints: Bool = false, runWebTests: Bool = false)
    {
        uiLogger = logger
        chirp = CanaryTest(configDirPath: configPath, savePath: savePath, testCount: timesToRun, interface: interface, debugPrints: debugPrints, runWebTests: runWebTests)
    }
    
    public func runTest(runAsync: Bool = true)
    {
        chirp.begin(runAsync: runAsync)
    }
    
    static public func printLog(_ message: String)
    {
        uiLogger.info(Logger.Message(stringLiteral: message))
        
        #if os(macOS)
        print(message)
        #endif
    }
}
