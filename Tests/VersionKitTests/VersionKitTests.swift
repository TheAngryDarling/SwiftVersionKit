import XCTest
@testable import VersionKit

final class VersionKitTests: XCTestCase {
    
    static let VERBOSE: Bool = {
        var rtn = (ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil) //Allows me to run individual test within Xcode and see output, while running
        
        if rtn { print("Running in verbose mode") }
        else { print("Running in silent mode") }
        
        return rtn
    }()
    
    let printResults = VersionTests.VERBOSE
    
    func testVersions() {
        let versions: [String] = ["1.0","1.0.1","1.0-R12A","1.0.1-R12A","1.0.1-R12A-ABCD+ASDF+RX2A"]
        if printResults { print("Testing single version format") }
        for (_, v) in versions.enumerated() {
            
            guard let ef = Version(v) else {
                XCTFail("Failed to parse version '\(v)'")
                continue
            }
            XCTAssert(ef.description == v, "Improper parsing of format '\(v)' to '\(ef.description)'")
            if printResults { print("\t" + v + " ------ " + ef.description) }
            
        }
        
        let multiVersions: [String] = {
            var rtn: [String] = []
            
            for i in 0..<versions.count-1 {
                var v:  String = versions[i]
                for x in (i+1)..<versions.count { v += " + " + versions[x] }
                rtn.append(v)
            }
            
            return rtn
        }()
        
        if printResults { print("\nTesting multi version format") }
        for (_, v) in multienumerated() {
            guard let ef = Version(v) else {
                XCTFail("Failed to parse version '\(v)'")
                continue
            }
            XCTAssert(ef.description == v, "Improper parsing of format '\(v)' to '\(ef.description)'")
            if printResults { print("\t" + v + " ------ " + ef.description) }
            
        }
    }
    
    func testNamedVersions() {
        let versionsNumbers: [String] = ["1.0","1.0.1","1.0-R12A","1.0.1+R12A"]
        let names: [String] = ["ProgramA", "Lib B", "APP124", "Program A B"]
        
        let versions: [String] = {
            var rtn: [String] = []
            for n in names {
                for v in versionsNumbers {
                    rtn.append(n + " " + v)
                }
            }
            return rtn
        }()
        
        if printResults { print("Testing single named version format") }
        for (_, v) in versions.enumerated() {
            //if i > 0 { break }
            guard let ef = NamedVersion(v) else {
                XCTFail("Failed to parse version '\(v)'")
                continue
            }
            XCTAssert(ef.description == v, "Improper parsing of format '\(v)' to '\(ef.description)'")
            if printResults { print("\t" + v + " ------ " + ef.description) }
            
        }
        
        let multiVersions: [String] = {
            var rtn: [String] = []
            
            for i in 0..<versions.count-1 {
                var v:  String = versions[i]
                for x in (i+1)..<versions.count { v += " + " + versions[x] }
                rtn.append(v)
            }
            
            return rtn
        }()
        
        if printResults { print("\nTesting multi named version format") }
        for (_, v) in multienumerated() {
            //if i > 0 { break }
            guard let ef = NamedVersion(v) else {
                XCTFail("Failed to parse version '\(v)'")
                continue
            }
            XCTAssert(ef.description == v, "Improper parsing of format '\(v)' to '\(ef.description)'")
            if printResults { print("\t" + v + " ------ " + ef.description) }
            
        }
    }


    static var allTests = [
        ("testVersions", testVersions),
        ("testNamedVersions",testNamedVersions)
    ]
}
