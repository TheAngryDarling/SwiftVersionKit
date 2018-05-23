# VersionKit

Used for storing version information or group of versions

Single Version Fields:
* Major: UInt
* Minor: UInt
* Revision: UInt <- Optional
* Prerelease: [String] <- Optional (- Seprator)
* Build: [String] <- Optional (+ Seperator)

## Usage

```Swift

//Version String Format: {Major}.{Minor}.{Revision}-{Prerelease}+{Build}
//Create simple versions
let versionBasic: Version = "1.0"
let vesionNormal: Version = "1.0.0"
let versionWithBuild: Version = "1.0.0-R2S3+R23D3"

//Used for grouping versions together
let versionCompound: Version = "1.0 + 1.0.0 + 1.0.0-R2S3+R23D3"

let versionGrouped: Version = versionBasic + vesionNormal + versionWithBuild

// Named Version String Format: {Name} {Version}
//Create simple Named Versions
let namedVersionBasic: NamedVersion = "Program A 1.0"
let namedVersionNormal: NamedVersion = "Library B 1.0.0"
let namedVersionWithBuild: NamedVersion = "VersionKit 1.0.0-R2S3+R23D3"

//Used for grouping named versions together
let namedCompound: NamedVersion = "Program A 1.0 + Library B 1.0.0 + VersionKit 1.0.0-R2S3+R23D3"

let versionGroup: NamedVersion = namedVersionBasic + namedVersionNormal + namedVersionWithBuild


if versionGroup.contains(namedVersionBasic) {
    //Found specific named version
}

if versionGroup.contains(versionWithName: "VersionKit", havingMajorVersion: 1) {
    //Found named version with major 1
}

if versionGroup.contains(versionWithName: "VersionKit") {
    //Found named version with any version
}


```

## Authors

* **Tyler Anger** - *Initial work* - [TheAngryDarling](https://github.com/TheAngryDarling)

## License

This project is licensed under Apache License v2.0 - see the [LICENSE.md](LICENSE.md) file for details

