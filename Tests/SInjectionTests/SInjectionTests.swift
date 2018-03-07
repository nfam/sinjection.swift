//
//  InjectionTests.swift
//
//  Created by Ninh on 21/09/2016.
//  Copyright © 2016 Ninh. All rights reserved.
//

import XCTest
import Foundation

@testable import SInjection

protocol Protocol1 {
    var text: String { get }
}

protocol Protocol2 {
    var text: String { get }
}

class ClassA: Protocol1, Protocol2 {
    let text = "A"
}

class ClassB: Protocol1, Protocol2 {
    let text = "B"
}

class ClassC: Protocol1, Protocol2 {
    let proto: Protocol1
    init(proto: Protocol1) {
        self.proto = proto
    }
    var text: String { return "C" + self.proto.text }
}

class ClassD: Protocol1, Protocol2 {
    let proto: Protocol2
    init(proto: Protocol2) {
        self.proto = proto
    }
    var text: String { return "D" + self.proto.text }
}

class SInjectionTests: XCTestCase {
    static var allTests = [
        ("SInjection#ok", testOK),
        ("SInjection#notDefined", testNotDefined),
        ("SInjection#circularDependency", testCircularDependency)
    ]

    func testOK() throws {
        let container = Container()
        container.set(forType: Protocol1.self) { _ in ClassA() }
        container.set(forType: Protocol2.self) { _ in ClassB() }
        container.set(forType: Protocol1.self, tag: "C") { resolver in
            return ClassC(proto: try resolver.resolve(forType: Protocol1.self))
        }
        try container.build()

        let proto1 = container.get(forType: Protocol1.self, tag: "C")

        XCTAssertEqual(proto1?.text, "CA")
    }

    func testNotDefined() throws {
        let container = Container()
        container.set(forType: Protocol1.self) { _ in ClassA() }
        container.set(forType: Protocol2.self) { _ in ClassB() }
        container.set(forType: Protocol1.self, tag: "C") { resolver in ClassC(proto: try resolver.resolve(forType: Protocol1.self, tag: "name")) }

        do {
            try container.build()
            XCTFail("Should have error.")
        }
        catch let error as InjectionError {
            XCTAssertEqual(error.description, "Service \"Protocol1#name\" is not defined.")
        }
    }

    func testCircularDependency() throws {
        let container = Container()
        container.set(forType: Protocol1.self) { resolver in ClassD(proto: try resolver.resolve(forType: Protocol2.self)) }
        container.set(forType: Protocol2.self) { resolver in ClassC(proto: try resolver.resolve(forType: Protocol1.self)) }

        do {
            try container.build()
            XCTFail("Should have error.")
        }
        catch let error as InjectionError {
            XCTAssert(
                error.description == "Circular dependency of Protocol1, Protocol2." ||
                error.description == "Circular dependency of Protocol2, Protocol1."
            )
        }
    }
}
