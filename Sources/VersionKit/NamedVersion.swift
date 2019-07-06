//
//  ProgramVersion.swift
//  Test
//
//  Created by Tyler Anger on 2018-03-14.
//  Copyright © 2018 Tyler Anger. All rights reserved.
//

import Foundation


// Map ProgramVersion to NamedVersion
public typealias ProgramVersion = NamedVersion

// Map LibraryVersion to NamedVersion
public typealias LibraryVersion = NamedVersion

// Map PackageVersion to NamedVersion
public typealias PackageVersion = NamedVersion



/// Storage for named version values
///    - single: Stores a single instance of a named version
///    - compound: Stores an array of named versions
public enum NamedVersion {
    
    /// Single instance of a named version.
    public struct SingleVersion {
        /// Name of object (eg. Program, Library)
        public let name: String
        /// Version of object
        public let version: Version
    }
    
    /// Single version with only one name and one version number
    public struct BasicVersion {
        /// Name of object (eg. Program, Library)
        public let name: String
        /// Version of object
        public let version: Version.SingleVersion
    }
    
    /// Regular Expression for checking for a single named version
    public static let SINGLE_VERSION_REGEX: String = "(\\w+(\\s\\w+)*)\\s+(" + Version.COMPOUND_VERSION_OPTIONAL_MINOR_REGEX + ")"
    
    /// Regular Expression for checking for a single named version
    public static let SINGLE_VERSION_BASIC_REGEX: String = "(\\w+(\\s\\w+)*)\\s+(" + Version.SINGLE_VERSION_OPTIONAL_MINOR_REGEX + ")"
    
    /// Regular Expression for checking for compound named versions
    public static let COMPOUND_VERSION_REGEX: String = "(" + SINGLE_VERSION_REGEX + ")(?:\\s+\\+\\s+(\(SINGLE_VERSION_REGEX)))*"
    
    /// Indicates the group locaton within the regular expression for the name of the named version on a single version regex
    private static let NAME_VALUE_RANGE_INDEX: Int = 1
    /// Indicates the group locaton within the regular expression for the version of the named version on a single version regex
    private static let VERSION_VALUE_RANGE_INDEX: Int = 3
    
    /// Basic instance of named version
    case basic(BasicVersion)
    /// Single instance of named version
    case single(SingleVersion)
    /// Compound group of named version
    case compound([SingleVersion])
    
    /// If the current version is a compound version, this method will sort the versions and save the new order
    public mutating func sort() {
        guard case let NamedVersion.compound(ary) = self else { return }
        let sA = ary.sorted()
        self = .compound(sA)
    }
    
    /// Copies the current version, sorts if its a compound version and returns the new version
    public func sorted() -> NamedVersion {
        guard case let NamedVersion.compound(ary) = self else { return self }
        let sA = ary.sorted()
        return .compound(sA)
    }
    
    /// Indicates if this is a basic version
    public var isBasicVersion: Bool {
        if case NamedVersion.basic = self { return true }
        else { return false }
    }
    
    /// Indicates if this is a single version.  Basic versions are considered single versions.
    public var isSingleVersion: Bool {
        if case NamedVersion.basic = self { return true }
        else if case NamedVersion.single = self { return true }
        else { return false }
    }
    
    /// Indicates if this is a compound version
    public var isCompoundVersion: Bool {
        if case NamedVersion.compound = self { return true }
        else { return false }
    }
    
    /// Returns an array of all versions stored in this instance.
    /// If this is a basic version it will create a single version for the array, if this is a single version the array contains one element, else will return all elements in the compound form
    public var versions: [SingleVersion] {
        var rtn: [SingleVersion] = []
        
        if case NamedVersion.basic(let v) = self {
            rtn.append(SingleVersion(name: v.name, version: Version(v.version)))
        } else if case NamedVersion.single(let v) = self {
            rtn.append(v)
        } else if case NamedVersion.compound(let ary) = self {
            rtn.append(contentsOf: ary)
        }
        
        return rtn
    }
    
    /// This is a basic version, will return BasicVersion object if one exists, or nil
    public var basicVersion: BasicVersion? {
        guard case NamedVersion.basic(let v) = self else { return nil }
        return v
    }
    
    /// If this is a single version, return the SingleVersion object
    /// This will also create and return when its a basic version
    public var singleVersion: SingleVersion? {
        if case NamedVersion.basic(let v) = self { return SingleVersion(name: v.name, version: Version(v.version)) }
        else if case NamedVersion.single(let v) = self { return v }
        return nil
    }
    
    /// Find and returns the first version with the matching conditions
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes a SingleVersion of the named version as its argument and returns a Boolean value indicating whether the element is a match.
    ///
    /// - returns: A single version if one is found, otherwise return nil
    func getVersion(where predicate: (SingleVersion) throws -> Bool) rethrows -> SingleVersion? {
        
        for v in self.versions {
            if try predicate(v) { return v }
        }
        
        return nil
    }
    
    
    /// Find and returns a version with the matching name
    ///
    /// - Parameters:
    ///   - name: The name of the version to find
    ///   - compareOptions: Options for comparing version name (Default: caseInsensitive)
    ///   - predicate: A closure that takes a SingleVersion of the named version as its argument and returns a Boolean value indicating whether the element is a match.
    ///
    /// - Returns: A single version if one is found, otherwise return nil
    func getVersion(withName name: String,
                    compareOptions: String.CompareOptions = .caseInsensitive,
                    where predicate: (SingleVersion) -> Bool = {_ in return true }) -> SingleVersion? {
        return self.getVersion {
            return (name.compare($0.name, options: compareOptions) == ComparisonResult.orderedSame) && predicate($0)
        }
    }
    
    /// Returns a Boolean value indicating whether the named version contains a version that satisfies the given predicate.
    /// - Parameters:
    ///   - predicate: A closure that takes a SingleVersion of the named version as its argument and returns a Boolean value indicating whether the element is a match.
    ///
    /// - Returns: true if the name version contains a version that satisfies predicate; otherwise, false.
    public func contains(where predicate: (SingleVersion) throws -> Bool) rethrows -> Bool {
        
        for v in self.versions {
            if try predicate(v) { return true }
        }
        
        return false
    }
    
    /// Checks to see if a version with a specific name exists
    /// - Parameters:
    ///   - name: The name of the version to find
    ///   - compareOptions: Options for comparing version name (Default: caseInsensitive)
    ///   - predicate: A closure that takes a SingleVersion of the named version as its argument and returns a Boolean value indicating whether the element is a match.
    ///
    /// - Returns: true if the name version contains a version that satisfies the conditions; otherwise, false.
    public func contains(versionWithName name: String,
                         compareOptions: String.CompareOptions = .caseInsensitive,
                         where predicate: (SingleVersion) -> Bool = {_ in return true }) -> Bool {
        return (self.getVersion(withName: name, compareOptions: compareOptions, where: predicate) != nil)
    }
    

    /// Checks to see if a version with a specific name and major version exists
    ///
    /// - Parameters:
    ///   - name: he name of the version to find
    ///   - compareOptions: Options for comparing version name (Default: caseInsensitive)
    ///   - major: The major value to compare to.
    ///   - predicate: A closure that takes a SingleVersion of the named version as its argument and returns a Boolean value indicating whether the element is a match.
    ///
    /// - Returns: true if the name version contains a version that satisfies the conditions; otherwise, false.
    public func contains(versionWithName name: String,
                         compareOptions: String.CompareOptions = .caseInsensitive,
                         havingMajorVersion major: UInt,
                         where predicate: (SingleVersion) -> Bool = {_ in return true }) -> Bool {
        return self.contains(versionWithName: name, compareOptions: compareOptions) {
            return ($0.version.major == major) && predicate($0)
        }
    }
    

    /// Checks to see if the given version resides within this instance
    ///
    /// - Parameter version: The version to look for
    /// - Returns: true if a version is found otherwise false
    public func contains(_ version: NamedVersion.SingleVersion) -> Bool {
        return self.versions.contains(version)
    }
    
    /// Checks to see if the given version resides within this instance
    ///
    /// - Parameter version: The version to look for
    /// - Returns: true if a version is found otherwise false
    public func contains(_ version: NamedVersion) -> Bool {
        var rtn: Bool = true
        let lhsVersions = self.versions
        for v in version.versions {
            rtn = rtn && lhsVersions.contains(v)
            if !rtn { break }
        }
        return rtn
    }
    
}


// MARK: init
public extension NamedVersion {
    /// Creates a new instance of single NamedVersion with a basic version
    init(_ version: BasicVersion) {
        self = .basic(version)
    }
    
    /// Creates a new instance of single NamedVersion with a single version
    init(_ version: SingleVersion) {
        self = .single(version)
    }
    
    /// Creates a new instance of a single NamedVersion with a the name and version
    init(name: String, version: Version.SingleVersion) {
        self.init(BasicVersion(name: name, version: version))
    }
    
    /// Creates a new instance of a single NamedVersion with a the name and version
    init(name: String, version: Version) {
        self.init(SingleVersion(name: name, version: version))
    }
    
    /// Creates a new instance of a single NamedVersion with a the name and versions
    init(name: String, versions: Version...) {
        precondition(versions.count > 0, "Atleast one versions must be provided")
        self.init(SingleVersion(name: name, version: Version(versions)))
    }
    
    /// Creates a new instance of a single NamedVersion with a the name and version information
    init(name: String, major: UInt, minor: UInt? = nil, revision: UInt? = nil, prerelease: [String] = [], build: [String] = []) {
        self.init(name: name,
                  version: Version(major: major,
                                   minor: minor,
                                   revision: revision,
                                   prerelease: prerelease,
                                   build: build))
    }
    
    /// Creates a new instane of a compound NamedVersion with the versions provided
    init(_ versions: [NamedVersion.SingleVersion]) {
        precondition(versions.count > 0, "Atleast one versions must be provided")
        self = .compound(versions)
    }
    
    /// Creates a new instane of a compound NamedVersion with the versions provided
    init(_ versions: NamedVersion.SingleVersion...) { self.init(versions) }
    /// Creates a new instane of a compound NamedVersion with the versions provided
    init(_ versions: [NamedVersion]) { self.init( versions.flatMap( { $0.versions }) ) }
    /// Creates a new instane of a compound NamedVersion with the versions provided
    init(_ versions: NamedVersion...) { self.init(versions) }
}

//MARK: CustomStringConvertible
extension NamedVersion: CustomStringConvertible {
    
    public var description: String {
        var rtn: String = ""
        
        switch(self) {
        case let .basic(v):
            rtn = v.description
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
    
    /// Provides a sorted string representation of the NamedVersion.  This only affects compound versions.  They get sorted before converting to strings
    var sortedDescription: String {
        var rtn: String = ""
        
        switch(self) {
        case let .basic(v):
            rtn = v.description
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
    
    
    /// Creates an instance initialized to the given string value.
    public init?(_ description: String) {
        //Make sure we start with a version pattern
        //let generalTestPattern: String = NamedVersion.SINGLE_VERSION_REGEX
        let generalTestPattern: String = NamedVersion.COMPOUND_VERSION_REGEX
        guard description.range(of: "^\(generalTestPattern)$",
            options: [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]) != nil else {
                debugPrint("String '\(description)' does not match pattern '^\(generalTestPattern)'")
                return nil }
        do {
            
            //let pattern: String = "(\(NamedVersion.SINGLE_VERSION_REGEX)( \\+|$))+"
            let pattern: String = NamedVersion.SINGLE_VERSION_REGEX
            let regx: NSRegularExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            
            let r = NSMakeRange(0, description.distance(from: description.startIndex, to: description.endIndex))
            
            let textResults = regx.matches(in: description, range: r)
            //print(description + " - \(textResults.count)")
            //print(pattern)
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
                let rName = Range<String.Index>(t.range(at: NamedVersion.NAME_VALUE_RANGE_INDEX), in: description)!
                let sName = String(description[rName])
                //print(sName)
                let rVersion = Range<String.Index>(t.range(at: NamedVersion.VERSION_VALUE_RANGE_INDEX), in: description)!
                let sVersion = String(description[rVersion])
                let ver = Version(groupVersion: sVersion)!
                
                versions.append(SingleVersion(name: sName, version: ver))
                
                
                let groupRange = Range<String.Index>(t.range, in: description)!
                let groupVersion = String(description[groupRange])
                guard let v = SingleVersion(groupVersion) else { return nil }
                versions.append(v)
                
            }
            
            if versions.count == 1 && versions[0].version.isSingleVersion {
                self = .basic(BasicVersion(name: versions[0].name,
                                           version: versions[0].version.singleVersion!))
            } else if versions.count == 1 { self = .single(versions[0]) }
            else if versions.count > 1 { self = .compound(versions) }
            else { return nil }
            
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
}

extension NamedVersion.SingleVersion: CustomStringConvertible {
    
     public var description: String { return  self.name + " " + self.version.description }
    
    
    /// Creates an instance initialized to the given string value.
    public init?(_ description: String) {
        //Make sure we start with a version pattern
        //let generalTestPattern: String = NamedVersion.SINGLE_VERSION_REGEX
        let generalTestPattern: String = NamedVersion.SINGLE_VERSION_REGEX
        guard description.range(of: "^\(generalTestPattern)$",
            options: [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]) != nil else {
                debugPrint("String '\(description)' does not match pattern '^\(generalTestPattern)'")
                return nil }
        do {
            
            //let pattern: String = "(\(NamedVersion.SINGLE_VERSION_REGEX)( \\+|$))+"
            let pattern: String = NamedVersion.SINGLE_VERSION_REGEX
            let regx: NSRegularExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            
            let r = NSMakeRange(0, description.distance(from: description.startIndex, to: description.endIndex))
            
            let textResults = regx.matches(in: description, range: r)
            guard textResults.count == 0 else { return nil }
            let t = textResults.first!
            
            let rName = Range<String.Index>(t.range(at: NamedVersion.NAME_VALUE_RANGE_INDEX), in: description)!
            let sName = String(description[rName])
            //print(sName)
            let rVersion = Range<String.Index>(t.range(at: NamedVersion.VERSION_VALUE_RANGE_INDEX), in: description)!
            let sVersion = String(description[rVersion])
            guard let ver = Version(groupVersion: sVersion) else { return nil }
            
            
            self.init(name: sName, version: ver)
            
            
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
}

extension NamedVersion.BasicVersion: CustomStringConvertible {
    
    public var description: String { return  self.name + " " + self.version.description }
    
    
    /// Creates an instance initialized to the given string value.
    public init?(_ description: String) {
        //Make sure we start with a version pattern
        //let generalTestPattern: String = NamedVersion.SINGLE_VERSION_REGEX
        let generalTestPattern: String = "^\(NamedVersion.SINGLE_VERSION_BASIC_REGEX)$"
        guard description.range(of: generalTestPattern,
            options: [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]) != nil else {
                debugPrint("String '\(description)' does not match pattern '\(generalTestPattern)'")
                return nil }
        do {
            
            //let pattern: String = "(\(NamedVersion.SINGLE_VERSION_REGEX)( \\+|$))+"
            let pattern: String = generalTestPattern
            let regx: NSRegularExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            
            let r = NSMakeRange(0, description.distance(from: description.startIndex, to: description.endIndex))
            
            let textResults = regx.matches(in: description, range: r)
            guard textResults.count == 1 else { return nil }
            let t = textResults.first!
            
            let rName = Range<String.Index>(t.range(at: NamedVersion.NAME_VALUE_RANGE_INDEX), in: description)!
            let sName = String(description[rName])
            //print(sName)
            let rVersion = Range<String.Index>(t.range(at: NamedVersion.VERSION_VALUE_RANGE_INDEX), in: description)!
            let sVersion = String(description[rVersion])
            guard let ver = Version.SingleVersion(groupVersion: sVersion) else { return nil }
            
            
            self.init(name: sName, version: ver)
            
            
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
}

extension NamedVersion: Hashable {
    #if !swift(>=4.1.4)
    public var hashValue: Int { return self.sortedDescription.hashValue }
    #endif
    #if swift(>=4.1.4)
    public func hash(into hasher: inout Hasher) {
        self.sortedDescription.hash(into: &hasher)
    }
    #endif
}

//MARK: ExpressibleByStringLiteral
extension NamedVersion: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        guard let s = NamedVersion(value) else {
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
extension NamedVersion.SingleVersion: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
       
        guard let s = NamedVersion.SingleVersion(value) else {
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
extension NamedVersion.BasicVersion: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        guard let s = NamedVersion.BasicVersion(value) else {
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


// MARK: Comparable
extension NamedVersion: Comparable {
    public static func ==(lhs: NamedVersion, rhs: NamedVersion) -> Bool {
        return (lhs.sortedDescription.lowercased() == rhs.sortedDescription.lowercased())
    }
    public static func <(lhs: NamedVersion, rhs: NamedVersion) -> Bool {
        let count = lhs.versions.count < rhs.versions.count ? lhs.versions.count : rhs.versions.count
        for i in 0..<count {
            if lhs.versions[i] < rhs.versions[i] { return true }
            else if lhs.versions[i] > rhs.versions[i] { return false }
        }
        if lhs.versions.count < rhs.versions.count { return true }
        return false
        
        //return (lhs.sortedDescription.lowercased() < rhs.sortedDescription.lowercased())
    }
}


extension NamedVersion.SingleVersion: Comparable {
    public static func ==(lhs: NamedVersion.SingleVersion, rhs: NamedVersion.SingleVersion) -> Bool {
        guard lhs.name == rhs.name && lhs.version == rhs.version else { return false }
        return true
    }
    public static func < (lhs: NamedVersion.SingleVersion, rhs: NamedVersion.SingleVersion) -> Bool {
        if lhs.name < rhs.name { return true }
        else if lhs.name > rhs.name { return false }
        else if lhs.version < rhs.version { return true }
        else { return false }
    }
}

extension NamedVersion.BasicVersion: Comparable {
    public static func ==(lhs: NamedVersion.BasicVersion, rhs: NamedVersion.BasicVersion) -> Bool {
        guard lhs.name == rhs.name && lhs.version == rhs.version else { return false }
        return true
    }
    public static func < (lhs: NamedVersion.BasicVersion, rhs: NamedVersion.BasicVersion) -> Bool {
        if lhs.name < rhs.name { return true }
        else if lhs.name > rhs.name { return false }
        else if lhs.version < rhs.version { return true }
        else { return false }
    }
    
    public static func ~=(lhs: NamedVersion.BasicVersion, rhs: NamedVersion.BasicVersion) -> Bool {
        guard lhs.name.compare(rhs.name, options: .caseInsensitive) == .orderedSame else { return false }
        return lhs.version ~= rhs.version
    }
}


//MARK: Operators
public func +(lhs: NamedVersion, rhs: NamedVersion) -> NamedVersion {
    var rtnAry: [NamedVersion.SingleVersion] = lhs.versions
    
    let toAdd: [NamedVersion.SingleVersion] = rhs.versions
    for v in toAdd {
        //Only add if not already there
        if !rtnAry.contains(v) { rtnAry.append(v) }
    }
    
    //rtnAry.sort()
    
    return NamedVersion.compound(rtnAry)
}


public func -(lhs: NamedVersion, rhs: NamedVersion) -> NamedVersion {
    //guard lhs.isSingleVersion else { return lhs }
    
    var ary: [NamedVersion.SingleVersion] = lhs.versions
    
    let toRemove: [NamedVersion.SingleVersion] = rhs.versions
    for v in toRemove {
        if let idx = ary.index(of: v) {
            ary.remove(at: idx)
        }
    }
    
    //ary.sort()
    
    return NamedVersion.compound(ary)
}

public func -(lhs: NamedVersion, rhs: NamedVersion.SingleVersion) -> NamedVersion {
    var ary: [NamedVersion.SingleVersion] = lhs.versions
    if let idx = ary.index(of: rhs) {
        ary.remove(at: idx)
    }
    return NamedVersion(ary)
}

public func +(lhs: NamedVersion.SingleVersion, rhs: NamedVersion.SingleVersion) -> NamedVersion {
    return NamedVersion([lhs, rhs])
}
public func +(lhs: NamedVersion, rhs: NamedVersion.SingleVersion) -> NamedVersion {
    var versions = lhs.versions
    versions.append(rhs)
    return NamedVersion(versions)
}
public func +(lhs: NamedVersion.SingleVersion, rhs: NamedVersion) -> NamedVersion {
    var versions = rhs.versions
    versions.append(lhs)
    return NamedVersion(versions)
}

public func +=(lhs: inout NamedVersion, rhs: NamedVersion.SingleVersion) {
    lhs = (lhs + rhs)
}
public func +=(lhs: inout NamedVersion, rhs: NamedVersion) {
    lhs = (lhs + rhs)
}
public func -=(lhs: inout NamedVersion, rhs: NamedVersion.SingleVersion) {
    lhs = (lhs - rhs)
}
public func -=(lhs: inout NamedVersion, rhs: NamedVersion) {
    lhs = (lhs - rhs)
}

// Check if lhs contains single version
public func ~=(lhs: NamedVersion, rhs: NamedVersion.SingleVersion) -> Bool {
    return lhs.versions.contains(rhs)
}
// Check if lhs contains all versions
public func ~=(lhs: NamedVersion, rhs: NamedVersion) -> Bool {
    var rtn: Bool = true
    let lhsVersions = lhs.versions
    for v in rhs.versions {
        rtn = rtn && lhsVersions.contains(v)
        if !rtn { break }
    }
    return rtn
}




