import XCTest
@testable import VersionKit
import UnitTestingHelper

final class VersionKitTests: XCTestCase {

    static let VERBOSE: Bool = {
        var rtn = (ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil) //Allows me to run individual test within Xcode and see output, while running

        if rtn { print("Running in verbose mode") }
        else { print("Running in silent mode") }

        return rtn
    }()

    let printResults = VersionKitTests.VERBOSE
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    struct EncodableValue<T>: Codable where T: Codable {
        let value: T
        public init(_ value: T) { self.value = value }
    }
    
    let major: UInt = 1
    let minor: UInt = 2
    let revision: UInt = 3
    let buildNumber: UInt = 1234
    let prerelease: [String] = ["R12A", "ABCD"]
    let build: [String] = ["ASDF", "RX2A"]
    
    func generateVersionStrings(includeMajorOnly: Bool = false) -> [String] {
        
        
        let verMajor = "\(major)"
        let verMajorMinor = "\(verMajor).\(minor)"
        let verMajorMinorRev = "\(verMajorMinor).\(revision)"
        let verMajorMinorRevBuildNumber = "\(verMajorMinorRev).\(buildNumber)"
        
        
        
        var rtn: [String] = []
        
        var verBase: [String] = [verMajorMinor, verMajorMinorRev, verMajorMinorRevBuildNumber]
        if includeMajorOnly {
            verBase.insert(verMajor, at: 0)
        }
        
        for base in verBase {
            rtn.append(base)
            for i in 0..<prerelease.count {
                var workingVer = base
                for x in 0...i {
                    workingVer += "-" + prerelease[x]
                }
                
                rtn.append(workingVer)
                
                for z in 0..<build.count {
                    var workingVer2 = workingVer
                    for x in 0...z {
                        workingVer2 += "+" + build[x]
                    }
                    rtn.append(workingVer2)
                }
                
            }
        }
        
        
        return rtn
    }
    
    func testBuildVersions() {
        let versions = generateVersionStrings()
        for ver in versions {
            print(ver)
        }
    }

    func testVersions() {
        //let versions: [String] = ["1.0","1.0-R12A","1.0.1","1.0.1-R12A","1.0.1-R12A-ABCD+ASDF+RX2A"]
        let versions: [String] = generateVersionStrings()
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

        var builtVersions: [Version] = []
        if printResults { print("\nTesting multi version format") }
        for (_, v) in multiVersions.enumerated() {
            guard let ef = Version(v) else {
                XCTFail("Failed to parse version '\(v)'")
                continue
            }
            builtVersions.append(ef)
            
            if printResults { print("\t" + v + " ------ " + ef.description) }
            if XCTAssertsEqual(v, ef.description, "Improper parsing of format '\(v)' to '\(ef.description)'") {
                if let data = XCTAssertsNoThrow(try encoder.encode(EncodableValue(ef))) {
                    if let newEf = XCTAssertsNoThrow(try decoder.decode(EncodableValue<Version>.self, from: data)) {
                        XCTAssertEqual(ef, newEf.value, "Improper parsing decodeing.  Expected: '\(ef)', found: '\(newEf)'")
                    }
                }
            }
        }

        builtVersions.sort()
         if printResults { print("\nSorted Versions") }
        for v in builtVersions {
            if printResults { print("\t" + v.description) }
        }
    }

    func testNamedVersions() {
        //let versionsNumbers: [String] = ["9","1.0","1.0.1","1.0-R12A","1.0.1+R12A"]
        let versionsNumbers =  generateVersionStrings(includeMajorOnly: true)
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
            if printResults { print("\t" + v + " ------ " + ef.description) }
            if XCTAssertsEqual(v, ef.description, "Improper parsing of format '\(v)' to '\(ef.description)'") {
                if let data = XCTAssertsNoThrow(try encoder.encode(EncodableValue(ef))) {
                    if let newEf = XCTAssertsNoThrow(try decoder.decode(EncodableValue<NamedVersion>.self, from: data)) {
                        XCTAssertEqual(ef, newEf.value, "Improper parsing decodeing.  Expected: '\(ef)', found: '\(newEf)'")
                    }
                }
            }
            
            

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

        var builtVersions: [NamedVersion] = []
        if printResults { print("\nTesting multi named version format") }
        for (_, v) in multiVersions.enumerated() {
            //if i > 0 { break }
            guard let ef = NamedVersion(v) else {
                XCTFail("Failed to parse version '\(v)'")
                continue
            }
            builtVersions.append(ef)
            XCTAssert(ef.description == v, "Improper parsing of format '\(v)' to '\(ef.description)'")
            if printResults { print("\t" + v + " ------ " + ef.description) }

        }

        builtVersions.sort()
        if printResults { print("\nSorted Versions") }
        for v in builtVersions {
            if printResults { print("\t" + v.description) }
        }
    }

    func testVersionSorting() {
        do {
            //let versions: [String] = ["1.0","1.0-R12A","1.0.1","1.0.1-R12A","1.0.1-R12A-ABCD+ASDF+RX2A"]
            let versions = generateVersionStrings()
            
            if printResults { print("Testing version sorting") }
            for i in 1..<versions.count {
                guard let v1 = Version(versions[i-1]) else {
                    XCTFail("Failed to parse version '\(versions[i-1])'")
                    continue
                }
                guard let v2 = Version(versions[i]) else {
                    XCTFail("Failed to parse version '\(versions[i])'")
                    continue
                }

                XCTAssert(v1 < v2, "Lessthan comparison failure '\(v1)' < '\(v2)'")

            }
        }

        do {
            let versions: [String] = [
                "APP124 1.0.1+R12A",
                "Lib B 1.0.1+R12A",
                "Program A B 1.0-R12A",
                "ProgramA 1.0-R12A"
                ]
            for i in 1..<versions.count {
                guard let v1 = NamedVersion(versions[i-1]) else {
                    XCTFail("Failed to parse version '\(versions[i-1])'")
                    continue
                }
                guard let v2 = NamedVersion(versions[i]) else {
                    XCTFail("Failed to parse version '\(versions[i])'")
                    continue
                }

                XCTAssert(v1 < v2, "Lessthan comparison failure '\(v1)' < '\(v2)'")

            }
        }

    }

    func testBasicNamedVersions() {
        do {
            let versions: [String] = [
                "APP124 1.0.1+R12A",
                "Lib B 1.0.1+R12A",
                "Program A B 1.0-R12A",
                "ProgramA 1.0-R12A"
                ]
            for i in 1..<versions.count {
                guard let v1 = NamedVersion.BasicVersion(versions[i-1]) else {
                    XCTFail("Failed to parse version '\(versions[i-1])'")
                    continue
                }
                XCTAssert(v1.description == versions[i-1], "Description comparison failure '\(v1.description)' == '\(versions[i-1])'")
                guard let v2 = NamedVersion.BasicVersion(versions[i]) else {
                    XCTFail("Failed to parse version '\(versions[i])'")
                    continue
                }
                XCTAssert(v2.description == versions[i], "Description comparison failure '\(v2.description)' == '\(versions[i])'")
                XCTAssert(v1 < v2, "Lessthan comparison failure '\(v1)' < '\(v2)'")

            }
        }
    }

    static var allTests = [
        ("testVersions", testVersions),
        ("testNamedVersions",testNamedVersions),
        ("testVersionSorting", testVersionSorting),
        ("testBasicNamedVersions", testBasicNamedVersions)
    ]
}
