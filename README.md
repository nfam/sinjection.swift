# SInjection
[![swift][swift-badge]][swift-url]
![platform][platform-badge]
[![build][travis-badge]][travis-url]
[![codecov][codecov-badge]][codecov-url]
![license][license-badge]

Simple Dependency Injection for Swift.

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/nfam/sinjection.git", majorVersion: 0, minor: 1)
    ]
)
```

## Usage

```swift
import SInjection

protocol DatabaseProtocol { }

class Database: DatabaseProtocol { }
class BackupRepository: DatabaseProtocol { }

class Repository {
    let database: DatabaseProtocol
    init(database: DatabaseProtocol) {
        self.database = database
    }
}
class MirrorService {
    let database: DatabaseProtocol
    init(database: DatabaseProtocol) {
        self.database = database
    }
}

func f() {
    let container = Container()
    container.set(forType: DatabaseProtocol.self) { _ in
        return Database()
    }
    container.set(forType: DatabaseProtocol.self, "mirror") { _ in
        return MirrorDatabase()
    }
    container.set(forType: Repository.self) { r in
        return Repository(database: try r.resolve(forType: Database.self))
    }
    container.set(forType: MirrorService.self) { r in
        return MirrorService(database: try r.resolve(forType: DatabaseProtocol.self, "mirror"))
    }

    try container.build()
    let repository: Repository = container.get(forType: Repository.self)!
}

```

[swift-url]: https://swift.org
[swift-badge]: https://img.shields.io/badge/Swift-3.1%20%7C%204.0-orange.svg?style=flat
[platform-badge]: https://img.shields.io/badge/Platforms-Linux%20%7C%20macOS%20%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgray.svg?style=flat
[travis-badge]: https://travis-ci.org/nfam/sinjection.swift.svg
[travis-url]: https://travis-ci.org/nfam/sinjection.swift
[codecov-badge]: https://codecov.io/gh/nfam/sinjection.swift/branch/master/graphs/badge.svg
[codecov-url]: https://codecov.io/gh/nfam/sinjection.swift/branch/master
[license-badge]: https://img.shields.io/github/license/nfam/sinjection.swift.svg