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
        public let buildNumber: UInt?
        public let prerelease: [String]
        public let build: [String]
        
        public init(major: UInt,
                    minor: UInt!,
                    revision: UInt?,
                    buildNumber: UInt? = nil,
                    prerelease: [String] = [],
                    build: [String] = []) {
            
            var rev = revision
            if rev == nil && buildNumber != nil {
                rev = 0
            }
            
            self.major = major
            self.minor = minor
            self.revision = rev
            self.buildNumber = buildNumber
            self.prerelease = prerelease
            self.build = build
        }
    }

    /// Regular Expression for checking for a single version
    public static let SINGLE_VERSION_REGEX: String = "(v|version |)(\\d+)\\.(\\d+)(?:\\.(\\d+)(?:\\.(\\d+))?)?((\\-\\w+)+)?((\\+\\w+)+)?"
    // swiftlint:disable:previous identifier_name line_length

    /// Regular Expression for checking for a single version with optional minor value
    internal static let SINGLE_VERSION_OPTIONAL_MINOR_REGEX: String = "(v|version |)(\\d+)(?:\\.(\\d+))?(?:\\.(\\d+)(?:\\.(\\d+))?)?((\\-\\w+)+)?((\\+\\w+)+)?"
    // swiftlint:disable:previous identifier_name line_length

    /// Regular Expression for checking for compound versions
    public static let COMPOUND_VERSION_REGEX: String = "(" + SINGLE_VERSION_REGEX + ")(?:\\s+\\+\\s+(\(SINGLE_VERSION_REGEX)))*"
    // swiftlint:disable:previous identifier_name line_length

    /// Regular Expression for checking for compound versions  with optional minor value
    public static let COMPOUND_VERSION_OPTIONAL_MINOR_REGEX: String = "(" + SINGLE_VERSION_OPTIONAL_MINOR_REGEX + ")(?:\\s+\\+\\s+(\(SINGLE_VERSION_OPTIONAL_MINOR_REGEX)))*"
    // swiftlint:disable:previous identifier_name line_length

    private static let MAJOR_VALUE_RANGE_INDEX: Int = 2 // swiftlint:disable:this identifier_name
    private static let MINOR_VALUE_RANGE_INDEX: Int = 3 // swiftlint:disable:this identifier_name
    private static let REVISION_VALUE_RANGE_INDEX: Int = 4 // swiftlint:disable:this identifier_name
    private static let BUILD_NUMBER_VALUE_RANGE_INDEX: Int = 5 // swiftlint:disable:this identifier_name
    private static let PRE_RELEASE_VALUE_RANGE_INDEX: Int = 6 // swiftlint:disable:this identifier_name
    private static let BUILD_VALUE_RANGE_INDEX: Int = 8 // swiftlint:disable:this identifier_name

    /// Single instance of version
    case single(SingleVersion)
    /// Compound group of named version
    case compound([SingleVersion])

    /// If the current version is a compound version, this method will sort the versions and save the new order
    public mutating func sort() {
        guard case let Version.compound(ary) = self else { return }
        self = .compound(ary.sorted())
    }

    /// Copies the current version, sorts if its a compound version and returns the new version
    public func sorted() -> Version {
        guard case let Version.compound(ary) = self else { return self }
        return .compound(ary.sorted())
    }

    /// Indicates if this is a single version or a compound version
    internal var isSingleVersion: Bool {
        guard case Version.single = self else { return false }
        return true
    }

    /// Returns an array of all versions stored in this instance.
    /// If this is a single version the array contains one element, else will return all elements in the compound form
    internal var versions: [SingleVersion] {
        var rtn: [SingleVersion] = []

        if case Version.single(let ver) = self {
            rtn.append(ver)
        } else if case Version.compound(let ary) = self {
            rtn.append(contentsOf: ary)
        }

        return rtn
    }

    /// If this is a single version, return the SingleVersion object
    public var singleVersion: SingleVersion? {
        guard case Version.single(let ver) = self else { return nil }
        return ver
    }

    public var major: UInt? { return self.singleVersion?.major }
    public var minor: UInt? { return self.singleVersion?.minor }
    public var revision: UInt? { return self.singleVersion?.revision }
    public var buildNumber: UInt? { return self.singleVersion?.buildNumber }
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
    init(major: UInt,
         minor: UInt,
         revision: UInt? = nil,
         buildNumber: UInt? = nil,
         prerelease: [String] = [],
         build: [String] = []) {
        self.init(SingleVersion(major: major,
                                minor: minor,
                                revision: revision,
                                buildNumber: buildNumber,
                                prerelease: prerelease,
                                build: build))
    }
    /// Creates a new instance of a single Version with the version information
    internal init(major: UInt,
                  minor: UInt?,
                  revision: UInt? = nil,
                  buildNumber: UInt? = nil,
                  prerelease: [String] = [],
                  build: [String] = []) {
        self.init(SingleVersion(major: major,
                                minor: minor,
                                revision: revision,
                                buildNumber: buildNumber,
                                prerelease: prerelease,
                                build: build))
    }
    /// Creates a new instane of a compound Version with the versions provided
    init(_ versions: [SingleVersion]) {
        precondition(versions.count > 0, "Must have alteast 1 version")
        // swiftlint:disable:next statement_position
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
        for ver in versions {
            vary.append(contentsOf: ver.versions)
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

    internal init?(versionString: String,
                   compoundPattern: String,
                   singlePattern: String) {
        //Make sure we start with a version pattern
        //let generalTestPattern: String = Version.SINGLE_VERSION_REGEX
        guard versionString.range(of: "^\(compoundPattern)$",
            options: [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]) != nil else {
                debugPrint("String '\(versionString)' does not match pattern '^\(compoundPattern)'")
                return nil }
        do {

            let regx: NSRegularExpression = try NSRegularExpression(pattern: singlePattern,
                                                                    options: .caseInsensitive)

            let fullVersonStringRange = NSRange(location: 0,
                                                length: versionString.distance(from: versionString.startIndex,
                                                                               to: versionString.endIndex))

            let textResults = regx.matches(in: versionString, range: fullVersonStringRange)
            //print(description + " - \(textResults.count)")

            var versions: [SingleVersion] = []
            for tResults in textResults {
                var iMajor: UInt = 0
                var iMinor: UInt? = nil
                var iRevision: UInt? = nil
                var iBuildNumber: UInt? = nil
                var saPrerelease: [String] = []
                var saBuild: [String] = []
                //var sBuild: String? = nil

                let rMajor = Range<String.Index>(tResults.range(at: Version.MAJOR_VALUE_RANGE_INDEX),
                                                 in: versionString)!
                iMajor = UInt(versionString[rMajor])!

                if tResults.range(at: Version.MINOR_VALUE_RANGE_INDEX).length > 0 {
                    let rMinor = Range<String.Index>(tResults.range(at: Version.MINOR_VALUE_RANGE_INDEX),
                                                     in: versionString)!
                    iMinor = UInt(versionString[rMinor])
                }

                if tResults.range(at: Version.REVISION_VALUE_RANGE_INDEX).length > 0 {
                    let rRevision = Range<String.Index>(tResults.range(at: Version.REVISION_VALUE_RANGE_INDEX),
                                                        in: versionString)!
                    iRevision = UInt(versionString[rRevision])
                }
                
                if tResults.range(at: Version.BUILD_NUMBER_VALUE_RANGE_INDEX).length > 0 {
                    let rBuildNumber = Range<String.Index>(tResults.range(at: Version.BUILD_NUMBER_VALUE_RANGE_INDEX),
                                                        in: versionString)!
                    iBuildNumber = UInt(versionString[rBuildNumber])
                }

                if tResults.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX).length > 0 {
                    let rBuild = Range<String.Index>(tResults.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX),
                                                     in: versionString)!
                    saPrerelease = versionString[rBuild].split(separator: "-").map({ String($0) })
                }

                if tResults.range(at: Version.BUILD_VALUE_RANGE_INDEX).length > 0 {
                    let rBuild = Range<String.Index>(tResults.range(at: Version.BUILD_VALUE_RANGE_INDEX),
                                                     in: versionString)!
                    saBuild = versionString[rBuild].split(separator: "+").map({ String($0) })
                }

                versions.append(SingleVersion(major: iMajor,
                                              minor: iMinor,
                                              revision: iRevision,
                                              buildNumber: iBuildNumber,
                                              prerelease: saPrerelease,
                                              build: saBuild))

            }
            if versions.count == 0 { return nil }
            self.init(versions)

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
     }

    internal init?(groupVersion: String) {
        self.init(versionString: groupVersion,
                  compoundPattern: Version.COMPOUND_VERSION_OPTIONAL_MINOR_REGEX,
                  singlePattern: Version.SINGLE_VERSION_OPTIONAL_MINOR_REGEX)
    }

    public var description: String {
        var rtn: String = ""

        switch self {
            case let .single(ver):
                rtn = ver.description
            case .compound(let ary):
                for (idx, ver) in ary.enumerated() {
                    if idx > 0 { rtn += " + " }
                    rtn += ver.description
                }
        }

        return rtn
    }

    public var sortedDescription: String {
        var rtn: String = ""

        switch self {
            case let .single(ver):
                rtn = ver.description
            case .compound(let ary):
                for (idx, ver) in ary.sorted().enumerated() {
                    if idx > 0 { rtn += " + " }
                    rtn += ver.description
                }
        }

        return rtn
    }
}

extension Version: Hashable {
    #if !swift(>=4.1.4)
    public var hashValue: Int { return self.sortedDescription.hashValue }
    // swiftlint:disable:previous legacy_hashing
    #endif
    #if swift(>=4.1.4)
    public func hash(into hasher: inout Hasher) {
        self.sortedDescription.hash(into: &hasher)
    }
    #endif
}

// MARK: Comparable
extension Version: Comparable {

    public static func ==(lhs: Version, rhs: Version) -> Bool {
        return (lhs.sortedDescription.lowercased() == rhs.sortedDescription.lowercased())
    }
    public static func <(lhs: Version, rhs: Version) -> Bool {
        let count = lhs.versions.count < rhs.versions.count ? lhs.versions.count : rhs.versions.count
        for idx in 0..<count {
            if lhs.versions[idx] < rhs.versions[idx] { return true }
            else if lhs.versions[idx] > rhs.versions[idx] { return false }
        }
        if lhs.versions.count < rhs.versions.count { return true }
        return false
        //return (lhs.sortedDescription.lowercased() < rhs.sortedDescription.lowercased())
    }

    public static func +(lhs: Version, rhs: Version) -> Version {
        var rtnAry: [SingleVersion] = lhs.versions

        let toAdd: [SingleVersion] = rhs.versions
        for ver in toAdd {
            //Only add if not already there
            if !rtnAry.contains(ver) { rtnAry.append(ver) }
        }

        //rtnAry.sort()

        return Version.compound(rtnAry)
    }

    public static func -(lhs: Version, rhs: Version) -> Version {
        guard !lhs.isSingleVersion else { return lhs }

        var ary: [SingleVersion] = lhs.versions

        let toRemove: [SingleVersion] = rhs.versions
        for ver in toRemove {
            if let idx = ary.index(of: ver) {
                ary.remove(at: idx)
            }
        }

        return Version.compound(ary)
    }

}

// MARK: ExpressibleByStringLiteral
extension Version: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let instance = Version(value) else {
            preconditionFailure("Invalid format '\(value)'")
        }
        self = instance

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
            lhs.buildNumber == rhs.buildNumber &&
            lhs.prerelease == rhs.prerelease &&
            lhs.build == rhs.build)
    }
    // swiftlint:disable:next cyclomatic_complexity
    public static func <(lhs: Version.SingleVersion, rhs: Version.SingleVersion) -> Bool {
        if lhs.major < rhs.major { return true }
        else if lhs.major > rhs.major { return false }

        if let lhsR = lhs.minor, let rhsR = rhs.minor {
            if lhsR < rhsR { return true }
            else if lhsR > rhsR { return false }
        }
        else if lhs.minor == nil && rhs.minor != nil { return true }
        else if lhs.minor != nil && rhs.minor == nil { return false }

        if let lhsR = lhs.revision, let rhsR = rhs.revision {
            if lhsR < rhsR { return true }
            else if lhsR > rhsR { return false }
        }
        else if lhs.revision == nil && rhs.revision != nil { return true }
        else if lhs.revision != nil && rhs.revision == nil { return false }
        
        if let lhsBN = lhs.buildNumber, let rhsBN = rhs.buildNumber {
            if lhsBN < rhsBN { return true }
            else if lhsBN > rhsBN { return false }
        }
        else if lhs.buildNumber == nil && rhs.buildNumber != nil { return true }
        else if lhs.buildNumber != nil && rhs.buildNumber == nil { return false }

        let lhsP = lhs.prerelease.reduce("", +)
        let rhsP = rhs.prerelease.reduce("", +)
        if lhsP < rhsP { return true }
        else if lhsP > rhsP { return false }

        let lhsB = lhs.build.reduce("", +)
        let rhsB = rhs.build.reduce("", +)
        if lhsB < rhsB { return true }
        else { return false }

    }

    public static func ~=(lhs: Version.SingleVersion, rhs: Version.SingleVersion) -> Bool {
        return (lhs.major == rhs.major &&
               (lhs.minor ?? 0) == (rhs.minor ?? 0) &&
               (lhs.revision ?? 0) == (rhs.revision ?? 0) &&
               (lhs.buildNumber ?? 0) == (rhs.buildNumber ?? 0) &&
               lhs.prerelease == rhs.prerelease &&
               lhs.build == rhs.build)
    }
}
// MARK: CustomStringConvertible
extension Version.SingleVersion: LosslessStringConvertible, ExpressibleByStringLiteral {

    internal init?(versionString: String, pattern: String) {
        //Make sure we start with a version pattern
        //let generalTestPattern: String = Version.SINGLE_VERSION_REGEX
        guard versionString.range(of: "^\(pattern)$",
            options: [String.CompareOptions.regularExpression, String.CompareOptions.caseInsensitive]) != nil else {
                debugPrint("String '\(versionString)' does not match pattern '^\(pattern)'")
                return nil }
        do {

            let regx: NSRegularExpression = try NSRegularExpression(pattern: "^\(pattern)$", options: .caseInsensitive)

            let fullVersonStringRange = NSRange(location: 0,
                                                length: versionString.distance(from: versionString.startIndex,
                                                                               to: versionString.endIndex))
            let textResults = regx.matches(in: versionString, range: fullVersonStringRange)
            guard let tResults = textResults.first, textResults.count == 1 else {
                return nil
            }

            var iMajor: UInt = 0
            var iMinor: UInt? = nil
            var iRevision: UInt? = nil
            var iBuildNumber: UInt? = nil
            var saPrerelease: [String] = []
            var saBuild: [String] = []
            //var sBuild: String? = nil

            let rMajor = Range<String.Index>(tResults.range(at: Version.MAJOR_VALUE_RANGE_INDEX),
                                             in: versionString)!
            iMajor = UInt(versionString[rMajor])!

            if tResults.range(at: Version.MINOR_VALUE_RANGE_INDEX).length > 0 {
                let rMinor = Range<String.Index>(tResults.range(at: Version.MINOR_VALUE_RANGE_INDEX),
                                                 in: versionString)!
                iMinor = UInt(versionString[rMinor])
            }

            if tResults.range(at: Version.REVISION_VALUE_RANGE_INDEX).length > 0 {
                let rRevision = Range<String.Index>(tResults.range(at: Version.REVISION_VALUE_RANGE_INDEX),
                                                    in: versionString)!
                iRevision = UInt(versionString[rRevision])
            }
            
            if tResults.range(at: Version.BUILD_NUMBER_VALUE_RANGE_INDEX).length > 0 {
                let rBuildNumber = Range<String.Index>(tResults.range(at: Version.BUILD_NUMBER_VALUE_RANGE_INDEX),
                                                    in: versionString)!
                iBuildNumber = UInt(versionString[rBuildNumber])
            }
            
            

            if tResults.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX).length > 0 {
                let rBuild = Range<String.Index>(tResults.range(at: Version.PRE_RELEASE_VALUE_RANGE_INDEX),
                                                 in: versionString)!
                saPrerelease = versionString[rBuild].split(separator: "-").map({ String($0) })
            }

            if tResults.range(at: Version.BUILD_VALUE_RANGE_INDEX).length > 0 {
                let rBuild = Range<String.Index>(tResults.range(at: Version.BUILD_VALUE_RANGE_INDEX),
                                                 in: versionString)!
                saBuild = versionString[rBuild].split(separator: "+").map({ String($0) })
            }

            self.init(major: iMajor,
                      minor: iMinor,
                      revision: iRevision,
                      buildNumber: iBuildNumber,
                      prerelease: saPrerelease,
                      build: saBuild)

        } catch {
            debugPrint(error)
            return nil
        }
    }

    /// Creates an instance initialized to the given string value.
    public init?(_ description: String) {
        self.init(versionString: description,
                  pattern: Version.SINGLE_VERSION_REGEX)
    }

    public init(stringLiteral value: String) {
        guard let instance = Version.SingleVersion(value) else {
            fatalError("Invalid SingleVersion string literal '\(value)'")
        }
        self = instance
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {

        self.init(stringLiteral: value)
    }

    internal init?(groupVersion: String) {
        self.init(versionString: groupVersion,
                  pattern: Version.SINGLE_VERSION_OPTIONAL_MINOR_REGEX)
    }

    public var description: String {
        var rtn: String = "\(self.major)"
        if let min = self.minor { rtn += ".\(min)" }
        if let rev = self.revision, rev > 0 { rtn += ".\(rev)" }
        if let bn = self.buildNumber, bn > 0 { rtn += ".\(bn)" }
        for pre in self.prerelease { rtn += "-" + pre }
        for bld in self.build { rtn += "+" + bld }
        //if let b = self.build { rtn += "-\(b)" }
        return rtn
    }
}

extension Version.SingleVersion: Codable {
    public enum CodingErrors: Swift.Error {
        case invalidVersion(String)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringVersion = try container.decode(String.self)
        guard let newVersion = Version.SingleVersion(stringVersion) else {
            throw CodingErrors.invalidVersion(stringVersion)
        }
        self = newVersion
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}

extension Version: Codable {
    public enum CodingErrors: Swift.Error {
        case invalidVersion(String)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringVersion = try container.decode(String.self)
        guard let newVersion = Version(stringVersion) else {
            throw CodingErrors.invalidVersion(stringVersion)
        }
        self = newVersion
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}

public func ==(lhs: Version, rhs: Version.SingleVersion) -> Bool {
    let rhsV = Version.compound([rhs])
    return lhs == rhsV
}
public func ==(lhs: Version.SingleVersion, rhs: Version) -> Bool {
    let lhsV = Version.compound([lhs])
    return lhsV == rhs
}
