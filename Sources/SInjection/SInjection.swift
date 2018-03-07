//
//  SInjection.swift
//
//  Created by Ninh on 21/09/2016.
//  Copyright © 2016 Ninh. All rights reserved.
//

public class Container {
    fileprivate var factories: [Key: ((Resolver) throws -> Any)]
    fileprivate var instances: [Key: Any]

    public init() {
        self.factories = [:]
        self.instances = [:]
    }

    public func set<Service>(
        forType type: Service.Type,
        tag: String? = nil,
        factory: @escaping (Resolver) throws -> Service
    ) {
        self.factories[Key(type, tag)] = factory
    }

    public func build() throws {
        let resolver = Resolver(self.factories)
        for key in self.factories.keys {
            _ = try resolver.resolve(key)
        }
        self.instances = resolver.instances
    }

    public func get<Service>(forType type: Service.Type, tag: String? = nil) -> Service? {
        return self.instances[Key(type, tag)] as? Service
    }
}

public class Resolver {
    fileprivate var factories: [Key: ((Resolver) throws -> Any)]
    fileprivate var instances: [Key: Any]
    fileprivate var required: [Key: Bool]

    fileprivate init(_ factories: [Key: ((Resolver) throws -> Any)]) {
        self.factories = factories
        self.instances = [:]
        self.required = [:]
    }

    fileprivate func resolve(_ key: Key) throws -> Any {
        if let instance = self.instances[key] {
            return instance
        }
        else if self.required[key] != nil {
            throw InjectionError("Circular dependency of " +
                self.required.keys.map { $0.description }.joined(separator: ", ") +
                "."
            )
        }
        else if let factory = self.factories[key] {
            self.required[key] = true
            let instance = try factory(self)
            self.instances[key] = instance
            self.required.removeValue(forKey: key)
            return instance
        }
        else {
            throw InjectionError("Service \"\(key)\" is not defined.")
        }
    }

    public func resolve<Service>(forType type: Service.Type, tag: String? = nil) throws -> Service {
        // swiftlint:disable:next force_cast
        return try self.resolve(Key(type, tag)) as! Service
    }
}

private struct Key {
    let type: Any.Type
    let tag: String?
    init<Service>(_ type: Service.Type, _ tag: String?) {
        self.type = type
        self.tag = tag
    }
}

extension Key: CustomStringConvertible {
    var description: String {
        return String(describing: type) + (tag != nil ? ("#"+tag!) : "")
    }
}

extension Key: Hashable {
    fileprivate var hashValue: Int {
        return String(describing: type).hashValue ^ (tag?.hashValue ?? 0)
    }

    fileprivate static func == (lhs: Key, rhs: Key) -> Bool {
        return lhs.type == rhs.type && lhs.tag == rhs.tag
    }
}

public struct InjectionError: Swift.Error, CustomStringConvertible {
    public let description: String
    fileprivate init(_ description: String) {
        self.description = description
    }
}
