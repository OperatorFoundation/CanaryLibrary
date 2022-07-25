//
//  BatchTestController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/23/17.
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
import Logging

import Chord

class TestController
{
    static let sharedInstance = TestController()
    
    func runSwiftTransportTest(forTransport transport: Transport) -> TestResult?
    {
        let transportController = TransportController(transport: transport, log: uiLogger)
        let success: Bool
        if let connection = Synchronizer.sync(transportController.startTransport)
        {
            uiLogger.debug("\n🧩 Launched \(transport). 🧩")
                    
            ///Connection Test
            let connectionTest = TransportConnectionTest(transportConnection: connection, canaryString: canaryString)
            success = connectionTest.run()
        }
        else
        {
            uiLogger.debug("\n🧩 Failed to Launch \(transport), creating a test result to track this failed connection. 🧩")
            success = false
        }
        
        // Save the result to a file
        let hostString = transport.serverIP + ":\(transport.port)"
        let result = TestResult(hostString: hostString, testDate: Date(), name: transport.name, success: success)
        let _ = save(result: result, testName: transport.name)
        
        sleep(1)
        return result
    }
    
    /// Tests ability to connect to a given web address without the use of transports
    func runWebTest(webTest: WebTest) -> TestResult?
    {
        var result: TestResult?
        
        ///Connection Test
        let connectionTest = ConnectionTest(testWebAddress: webTest.website, canaryString: nil)
        let success = connectionTest.run()
        
        result = TestResult(hostString: webTest.website, testDate: Date(), name: webTest.name, success: success)
        
        // Save this result to a file
        let _ = save(result: result!, testName: webTest.name)
        
        sleep(2)
        return result
    }
    
    /// Saves the provided test results to a csv file with a filename that contains a timestamp.
    /// If a file with this name already exists it will append the results to the end of the file.
    ///
    /// - Parameter result: The test result information to be saved. The type is a TestResult struct.
    /// - Returns: A boolean value indicating whether or not the results were saved successfully.
    func save(result: TestResult, testName: String) -> Bool
    {
        let resultString = "\(result.testDate), \(result.hostString), \(testName), \(result.success)\n"
        
        guard let resultData = resultString.data(using: .utf8)
            else { return false }
        
        guard let resultURL = getDocumentURL()
        else
        {
            print("Unable to save result data.")
            return false
        }

        if FileManager.default.fileExists(atPath: resultURL.path)
        {
            // We already have a file at this address let's add out results to the end of it.
            guard let fileHandler = FileHandle(forWritingAtPath: resultURL.path)
                else
            {
                uiLogger.info("\n🛑  Error creating a file handler to write to \(resultURL.path)\n")
                return false
            }
            
            fileHandler.seekToEndOfFile()
            fileHandler.write(resultData)
            fileHandler.closeFile()
            
            uiLogger.info("\nSaved test results to file: \(resultURL.path)")
            return true
        }
        else
        {
            // Make a new csv file for our test results
            // The first row should be our labels
            let labelRow = "TestDate, ServerIP, Transport, Success\n"
            guard let labelData = labelRow.data(using: .utf8)
                else { return false }
            
            // Append our results to the label row
            let newFileData = labelData + resultData
            
            // Save the new file
            let saved = FileManager.default.createFile(atPath: resultURL.path, contents: newFileData, attributes: nil)
            print("Test results saved? \(saved.description)")
            
            return saved
        }
    }
    
    func test(transport: Transport, interface: String?, debugPrints: Bool = false)
    {
        AdversaryLabController.sharedInstance.launchAdversaryLab(transport: transport, interface: interface, debugPrints: debugPrints)
        
        print("Testing \(transport.name) transport...")
        
        if let transportTestResult = self.runSwiftTransportTest(forTransport: transport)
        {
            uiLogger.debug("\n✔️  Received a new result when testing \(transport.name) transport.\n")
            AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: transportTestResult)
        }
        else
        {
            uiLogger.debug("\n🛑  Received a nil result when testing \(transport.name) transport.\n")
            AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: nil)
        }
    }
    
    func test(webTest: WebTest, interface: String?, debugPrints: Bool = false)
    {
        AdversaryLabController.sharedInstance.launchAdversaryLab(webTest: webTest, interface: interface, debugPrints: debugPrints)
        
        print("Testing web address \(webTest)")
        
        if let webTestResult = self.runWebTest(webTest: webTest)
        {
            //print("Test result for \(transport.name):\n\(webTestResult)\n")
            AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: webTestResult)
        }
        else
        {
            uiLogger.info("\n🛑  Received a nil result when testing \(webTest.name) web address.")
            AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: nil)
        }
    }
    
    func getNowAsString() -> String
    {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate, .withColonSeparatorInTime]
        var dateString = formatter.string(from: Date())
        dateString = dateString.replacingOccurrences(of: "-", with: "_")
        dateString = dateString.replacingOccurrences(of: ":", with: "_")
        
        return dateString
    }
    
    func getDocumentURL() -> URL?
    {
        if let directoryURL = getApplicationSupportURL()
        {
            let documentURL = directoryURL.appendingPathComponent ("\(resultsFileName)\(getNowAsString()).\(resultsExtension)")
            return documentURL
        }
        else
        {
            print("An error occurred while trying to create a document URL.")
            return nil
        }
    }
    
}
