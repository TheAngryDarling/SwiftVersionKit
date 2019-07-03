//
//  Version.swift
//
//  Created by Tyler Anger on 2018-03-14.
//  Copyright © 2018 Tyler Anger. All rights reserved.
//

import Foundation

/// Storage for version values
/// - single: Stores a single instance of a version
/// - compound: Stores an array of versions
public enum Version {
    
    /// Single instance of a version.
    public struct SingleVersion {
        public let major: UInt
        public let minor: UInt!
        public let revision: UInt?
        public let prerelease: [String]
        public let build: [String]
    }
    
    /// Regular Expression for checking for a single version
    public static let SINGLE_VERSION_REGEX: String = "(v|version |)(\\d+)\\.(\\d+)(?:\\.(\\d+))?((\\-\\w+)+)?((\\+\\w+)+)?"
    /// Regular Expression for checking for a single version with optional minor value
    internal static let SINGLE_VERSION_OPTIONAL_MINOR_REGEX: String = "(v|version |)(\\d+)(?:\\.(\\d+))?(?:\\.(\\d+))?((\\-\\w+)+)?((\\+\\w+)+)?"
    /// Regular Expression for checking for compound versions
    public static let COMPOUND_VERSION_REGEX: String = "(" + SINGLE_VERSION_REGEX + ")(?:\\s+\\+\\s+(\(SINGLE_VERSION_REGEX)))*"
    /// Regular Expression for checking for compound versions  with optional minor value
    public static let COMPOUND_VERSION_OPTIONAL_MINOR_REGEX: String = "(" + SINGLE_VERSION_OPTIONAL_MINOR_REGEX + ")(?:\\s+\\+\\s+(\(SINGLE_VERSION_OPTIONAL_MINOR_REGEX)))*"
    
    
    private static let MAJOR_VALUE_RANGE_INDEX: Int = 2
    private static let MINOR_VALUE_RANGE_INDEX: Int = 3
    private static let REVISION_VALUE_RANGE_INDEX: Int = 4
    private static let PRE_RELEASE_VALUE_RANGE_INDEX: Int = 5
    private static let BUILD_VALUE_RANGE_INDEX: Int = 7
    
    /// Single instance of version
    case single(SingleVersion)
    /// Compound group of named version
    case compound([SingleVersion])
    
    /// If the current version is a compound version, this method will sort the versions and save the new order
    public mutating func sort() {
        guard case let Version.compound(ary) = self else { return }
        let sA = ary.sorted()
        self = .compound(sA)
    }
    
    /// Copies the current version, sorts if its a compound version and returns the new version
    public func sorted() -> Version {
        guard case let Version.compound(ary) = self else { return self }
        let sA = ary.sorted()
        return .compound(sA)
    }
    
    /// Indicates if this is a single version or a compound version
    internal var isSingleVersion: Bool {
        if case Version.single = self { return true }
        else { return false }
    }
    
    /// Returns an array of all versions stored in this instance.
    /// If this is a single version the array contains one element, else will return all elements in the compound form
    internal var versions: [SingleVersion] {
        var rtn: [SingleVersion] = []
        
        if case Version.single(let v) = self {
            rtn.append(v)
        } else if case Version.compound(let ary) = self {
            rtn.append(contentsOf: ary)
        }
        
        return rtn
    }
    
    /// If this is a single version, return the SingleVersion object
    public var singleVersion: SingleVersion? {
        guard case Version.single(let v) = self else { return nil }
        return v
    }
    
    public var major: UInt? { return self.singleVersion?.major }
    public var minor: UInt? { return self.singleVersion?.minor }
    public var revision: UInt? { return self.singleVersion?.revision }
    public var prerelease: [String]? { return self.singleVersion?.prerelease }
    public var build: [String]? { return self.singleVersion?.build }
    
}

// MARK: - init
public extension Version {
    /// Creates a new instance of single Version with a single version
    init(_ version: SingleVersion) {
        self = .single(version)
    }
    /// Creates a new instance of a single Version with the version information
    init(major: UInt, minor: UInt, revision: UInt? = nil, prerelease: [String] = [], build: [String] = []) {
        self.init(SingleVersion(major: major, minor: minor, revision: revision, prerelease: prerelease, build: build))
    }
    /// Creates a new instance of a single Version with the version information
    internal init(major: UInt, minor: UInt?, revision: UInt? = nil, prerelease: [String] = [], build: [String] = []) {
        self.init(SingleVersion(major: major, minor: minor, revision: revision, prerelease: prerelease, build: build))
    }
    /// Creates a new instane of a compound Version with the versions provided
    init(_ versions: [SingleVersion]) {
        precondition(versions.count > 0, "Must have alteast 1 version")
        if versions.count == 1 { self = .single(versions[0]) }
        else { self = .compound(versions) }
    }
    /// Creates a new instane of a compound Version with the versions provided
    init(_ versions: SingleVersion...) {
        self.init(versions)
    }
    /// Creates a new instane of a compound Version with the versions provided
    init(_ versions: [Version]) {
        var vary: [SingleVersion] = []
        for v in versions {
            vary.append(contentsOf: v.versions)
        }
        self.init(vary)
    }
    /// Creates a new instane of a compound Version with the versions provided
    init(_ versions: Version...) {
        self.init(versions)
    }
}

// MARK: LosslessStringConvertible
extension Version: LosslessStringConvertible {
    
    internal init?(versionString: String, compoundPattern: String, singlePattern: String) {
        //Make sure we start with a version pattern
        //let generalTestPattern: String = Version.SINGLE_VERSION_REGEX
        guard versionString.range(of: "^\(compoundPattern)$",
            options: [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]) != nil else {
                debugPrint("String '\(versionString)' does not match pattern '^\(compoundPattern)'")
                return nil }
        do {
            
            
            let regx: NSRegularExpression = try NSRegularExpression(pattern: singlePattern, options: .caseInsensitive)
            
            let r = NSMakeRange(0, versionString.distance(from: versionString.startIndex, to: versionString.endIndex))
            
            let textResults = regx.matches(in: versionString, range: r)
            //print(description + " - \(textResults.count)")
            
            var versions: [SingleVersion] = []
            for t in textResults {
                /*for i in 0..<t.numberOfRanges {
                 let r = t.range(at: i)
                 if r.length > 0 {
                 let rS = Range<String.Index>(t.range(at: i), in: description)!
                 print("\t[\(i)]: \(description[rS])")
                 } else {
                 print("\t[\(i)]: ")
                 }
                 }*/
                
                var iMajor: UInt = 0
                var iMinor: UInt? = nil
                var iRevision: UInt? = nil
                var saPrerelease: [String] = []
                var saBuild: [String] = []
                //var sBuild: String? = nil
                
                let rMajor = Range<String.Index>(t.range(at: Version.MAJOR_VALUE_RANGE_INDEX), in: versionString)!
                iMajor = UInt(versionString[rMajor])!
                
                if t.range(at: Version.MINOR_VALUE_RANGE_INDEX).length > 0 {
                    let rMinor = Range<String.Index>(t.range(at: Version.MINOR_VALUE_RANGE_INDEX), in: versionString)!
                    iMinor = UInt(versionString[rMinor])
                }
                
                if t.range(at: Version.REVISION_VALUE_RANGE_INDEX).length > 0 {
                    let rRevision = Range<String.Index>(t.range(at: Version.REVISION_VALUE_RANGE_INDEX), in: versionString)!
                    iRevision = UInt(versionString[rRevision])
                }
                
                if t.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX).length > 0 {
                    let rBuild = Range<String.Index>(t.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX), in: versionString)!
                    saPrerelease = versionString[rBuild].split(separator: "-").map({ String($0) })
                }
                
                if t.range(at: Version.BUILD_VALUE_RANGE_INDEX).length > 0 {
                    let rBuild = Range<String.Index>(t.range(at: Version.BUILD_VALUE_RANGE_INDEX), in: versionString)!
                    saBuild = versionString[rBuild].split(separator: "+").map({ String($0) })
                }
                
                
                /*if t.range(at: Version.BUILD_VALUE_RANGE_INDEX).length > 0 {
                 let rBuild = Range<String.Index>(t.range(at: Version.BUILD_VALUE_RANGE_INDEX), in: description)!
                 sBuild = String(description[rBuild])
                 }*/
                
                versions.append(SingleVersion(major: iMajor, minor: iMinor, revision: iRevision, prerelease: saPrerelease, build: saBuild))
                
            }
            if versions.count == 0 { return nil }
            self.init(versions)
            //if versions.count == 1 { self = versions[0] }
            //else if versions.count > 1 { self = .compound(versions) }
            //else { return nil }
            
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
    
     /// Creates an instance initialized to the given string value.
     public init?(_ description: String) {
        self.init(versionString: description,
                  compoundPattern: Version.COMPOUND_VERSION_REGEX,
                  singlePattern: Version.SINGLE_VERSION_REGEX)
        
        /*
        //Make sure we start with a version pattern
        //let generalTestPattern: String = Version.SINGLE_VERSION_REGEX
        let generalTestPattern: String = Version.COMPOUND_VERSION_REGEX
        guard description.range(of: "^\(generalTestPattern)$",
                                options: [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]) != nil else {
                                    debugPrint("String '\(description)' does not match pattern '^\(generalTestPattern)'")
                                    return nil }
        do {
            
            //let pattern: String = "(\(Version.SINGLE_VERSION_REGEX)( \\+|$))+"
            let pattern: String = Version.SINGLE_VERSION_REGEX
            //print(pattern)
            let regx: NSRegularExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            
            let r = NSMakeRange(0, description.distance(from: description.startIndex, to: description.endIndex))
            
            let textResults = regx.matches(in: description, range: r)
            //print(description + " - \(textResults.count)")
            
            var versions: [SingleVersion] = []
            for t in textResults {
                /*for i in 0..<t.numberOfRanges {
                    let r = t.range(at: i)
                    if r.length > 0 {
                        let rS = Range<String.Index>(t.range(at: i), in: description)!
                        print("\t[\(i)]: \(description[rS])")
                    } else {
                        print("\t[\(i)]: ")
                    }
                }*/
                
                var iMajor: UInt = 0
                var iMinor: UInt? = nil
                var iRevision: UInt? = nil
                var saPrerelease: [String] = []
                var saBuild: [String] = []
                //var sBuild: String? = nil
                
                let rMajor = Range<String.Index>(t.range(at: Version.MAJOR_VALUE_RANGE_INDEX), in: description)!
                iMajor = UInt(description[rMajor])!
                
                let rMinor = Range<String.Index>(t.range(at: Version.MINOR_VALUE_RANGE_INDEX), in: description)!
                iMinor = UInt(description[rMinor])!
                if t.range(at: Version.REVISION_VALUE_RANGE_INDEX).length > 0 {
                    let rRevision = Range<String.Index>(t.range(at: Version.REVISION_VALUE_RANGE_INDEX), in: description)!
                    iRevision = UInt(description[rRevision])
                }
                
                if t.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX).length > 0 {
                    let rBuild = Range<String.Index>(t.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX), in: description)!
                    saPrerelease = description[rBuild].split(separator: "-").map({ String($0) })
                }
                
                if t.range(at: Version.BUILD_VALUE_RANGE_INDEX).length > 0 {
                    let rBuild = Range<String.Index>(t.range(at: Version.BUILD_VALUE_RANGE_INDEX), in: description)!
                    saBuild = description[rBuild].split(separator: "+").map({ String($0) })
                }
                
                
                /*if t.range(at: Version.BUILD_VALUE_RANGE_INDEX).length > 0 {
                    let rBuild = Range<String.Index>(t.range(at: Version.BUILD_VALUE_RANGE_INDEX), in: description)!
                    sBuild = String(description[rBuild])
                }*/
                
                versions.append(SingleVersion(major: iMajor, minor: iMinor, revision: iRevision, prerelease: saPrerelease, build: saBuild))
                
            }
            if versions.count == 0 { return nil }
            self.init(versions)
            //if versions.count == 1 { self = versions[0] }
            //else if versions.count > 1 { self = .compound(versions) }
            //else { return nil }
            
        } catch {
            debugPrint(error)
            return nil
        }
        */
     }
    
    internal init?(groupVersion: String) {
        self.init(versionString: groupVersion,
                  compoundPattern: Version.COMPOUND_VERSION_OPTIONAL_MINOR_REGEX,
                  singlePattern: Version.SINGLE_VERSION_OPTIONAL_MINOR_REGEX)
    }
    
    
    
    public var description: String {
        var rtn: String = ""
        
        switch(self) {
            case let .single(v):
                rtn = v.description
            case .compound(let ary):
                for (i, a) in ary.enumerated() {
                    if i > 0 { rtn += " + " }
                    rtn += a.description
                }
        }
        
        return rtn
    }
    
    public var sortedDescription: String {
        var rtn: String = ""
        
        switch(self) {
        case let .single(v):
            rtn = v.description
        case .compound(let ary):
            for (i, a) in ary.sorted().enumerated() {
                if i > 0 { rtn += " + " }
                rtn += a.description
            }
        }
        
        return rtn
    }
}

extension Version: Hashable {
    #if !swift(>=4.1.4)
    public var hashValue: Int { return self.sortedDescription.hashValue }
    #endif
    #if swift(>=4.1.4)
    public func hash(into hasher: inout Hasher) {
        self.sortedDescription.hash(into: &hasher)
    }
    #endif
}

//MARK: Comparable
extension Version: Comparable {
    
    public static func ==(lhs: Version, rhs: Version) -> Bool {
        return (lhs.sortedDescription.lowercased() == rhs.sortedDescription.lowercased())
    }
    public static func <(lhs: Version, rhs: Version) -> Bool {
        let count = lhs.versions.count < rhs.versions.count ? lhs.versions.count : rhs.versions.count
        for i in 0..<count {
            if lhs.versions[i] < rhs.versions[i] { return true }
            else if lhs.versions[i] > rhs.versions[i] { return false }
        }
        if lhs.versions.count < rhs.versions.count { return true }
        return false
        //return (lhs.sortedDescription.lowercased() < rhs.sortedDescription.lowercased())
    }
    
    public static func +(lhs: Version, rhs: Version) -> Version {
        var rtnAry: [SingleVersion] = lhs.versions
        
        let toAdd: [SingleVersion] = rhs.versions
        for v in toAdd {
            //Only add if not already there
            if !rtnAry.contains(v) { rtnAry.append(v) }
        }
        
        //rtnAry.sort()
        
        return Version.compound(rtnAry)
    }
    
    public static func -(lhs: Version, rhs: Version) -> Version {
        guard !lhs.isSingleVersion else { return lhs }
        
        var ary: [SingleVersion] = lhs.versions
        
        let toRemove: [SingleVersion] = rhs.versions
        for v in toRemove {
            if let idx = ary.index(of: v) {
                ary.remove(at: idx)
            }
        }
        
        //ary.sort()
        
        return Version.compound(ary)
    }
    
}

// MARK: ExpressibleByStringLiteral
extension Version: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let s = Version(value) else {
            preconditionFailure("Invalid format '\(value)'")
        }
        self = s
        
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        
        self.init(stringLiteral: value)
    }
    
}

// MARK: - SingleVersion
// MARK: -
// MARK: Comparable
extension Version.SingleVersion: Comparable {
    
    
    public static func ==(lhs: Version.SingleVersion, rhs: Version.SingleVersion) -> Bool {
        return (lhs.major == rhs.major &&
            lhs.minor == rhs.minor &&
            lhs.revision == rhs.revision &&
            lhs.prerelease == rhs.prerelease &&
            lhs.build == rhs.build)
    }
    
    public static func <(lhs: Version.SingleVersion, rhs: Version.SingleVersion) -> Bool {
        if lhs.major < rhs.major { return true }
        else if lhs.major > rhs.major { return false }
        
        /*if lhs.minor < rhs.minor { return true }
        else if lhs.minor > rhs.minor { return false }*/
        
        if let lhsR = lhs.minor, let rhsR = rhs.minor {
            if lhsR < rhsR { return true }
            else if lhsR < rhsR { return false }
        }
        else if lhs.minor == nil && rhs.minor != nil { return true }
        else if lhs.minor != nil && rhs.minor == nil { return false }
        
        
        if let lhsR = lhs.revision, let rhsR = rhs.revision {
            if lhsR < rhsR { return true }
            else if lhsR < rhsR { return false }
        }
        else if lhs.revision == nil && rhs.revision != nil { return true }
        else if lhs.revision != nil && rhs.revision == nil { return false }
        
        let lhsP = lhs.prerelease.reduce("", +)
        let rhsP = rhs.prerelease.reduce("", +)
        if lhsP < rhsP { return true }
        else if lhsP > rhsP { return false }
        
        let lhsB = lhs.build.reduce("", +)
        let rhsB = rhs.build.reduce("", +)
        if lhsB < rhsB { return true }
        else { return false }
        
    }
}
// MARK: CustomStringConvertible
extension Version.SingleVersion: CustomStringConvertible {
    public var description: String {
        var rtn: String = "\(self.major)"
        if let m = self.minor { rtn += ".\(m)" }
        if let r = self.revision, r > 0 { rtn += ".\(r)" }
        for p in self.prerelease { rtn += "-" + p }
        for b in self.build { rtn += "+" + b }
        //if let b = self.build { rtn += "-\(b)" }
        return rtn
    }
}

