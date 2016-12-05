//
//  SwiftDecodePipeline.swift
//  Pods
//
//  Created by Héctor Ramón on 05/12/2016.
//
//

import Foundation
import SwiftyJSON

// Pipe operator
precedencegroup PipePrecedence {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

infix operator |> : PipePrecedence

public func |> <T,U>(lhs: T, rhs: (T) -> U) -> U {
    return rhs(lhs)
}

// Basic types
public enum Result<E, V> {
    case error(E), ok(V)
}

public typealias Decoder<T> = (JSON) -> Result<String, T>

// Composable functions
public func decode<A>(_ value: A) -> Decoder<A> {
    return { json in return .ok(value) }
}

public func required<A>(_ decoder: @escaping Decoder<A?>) -> Decoder<A> {
    return { json in
        let result = decoder(json)
        
        switch result {
        case .error(let error): return .error(error)
        case .ok(let value):
            if let unwrap = value {
                return .ok(unwrap)
            } else {
                return .error("Value is required")
            }
        }
    }
}

public func required<A, B>(_ key: String, _ valDecoder: @escaping Decoder<A>)
    -> (_ decoder: @escaping Decoder<(A) -> B>) -> Decoder<B> {
        return custom(field(key, valDecoder))
}

public func optional<A, B>(_ key: String, _ valDecoder: @escaping Decoder<A>)
    -> (_ decoder: @escaping Decoder<(A?) -> B>) -> Decoder<B> {
        let fieldDecoder = field(key, valDecoder)
        
        return custom { json in
            let result = fieldDecoder(json)
            
            switch result {
            case .error: return .ok(nil)
            case .ok(let value): return .ok(value)
            }
        }
}

public func hardcode<A, B>(_ value: A)
    -> (_ decoder: @escaping Decoder<(A) -> B>) -> Decoder<B> {
        return custom(decode(value))
}

public func map<A, B>(_ f: @escaping (A) -> B) -> (_ decoder: @escaping Decoder<A>) -> Decoder<B> {
    return { decoder in
        return { json in
            let result = decoder(json)
            
            switch result {
            case .error(let error): return .error(error)
            case .ok(let value): return .ok(f(value))
            }
        }
    }
}

public func custom<A, B>(_ valDecoder: @escaping Decoder<A>)
    -> (_ decoder: @escaping Decoder<(A) -> B>) -> Decoder<B> {
        return { decoder in
            return { json in
                let result = decoder(json)
                let valResult = valDecoder(json)
                
                switch result {
                case .error(let error): return .error(error)
                case .ok(let aToB):
                    switch valResult {
                    case .error(let error): return .error(error)
                    case .ok(let a):
                        return .ok(aToB(a))
                    }
                }
            }
        }
}

public func field<A>(_ key: String, _ decoder: @escaping Decoder<A>) -> Decoder<A> {
    return { json in return decoder(json[key]) }
}

public func array<A>(_ decoder: @escaping Decoder<A>) -> Decoder<[A]> {
    return { json in
        if let value = json.array {
            var result: [A] = []
            
            for jsonElement in value {
                let decodeResult = decoder(jsonElement)
                switch decodeResult {
                case .error(let error): return .error(error)
                case .ok(let element):
                    result.append(element)
                }
            }
            
            return .ok(result)
        } else {
            return .error("Invalid array")
        }
    }
}

// Primitives
public let int: Decoder<Int> = { json in
    if let value = json.int {
        return .ok(value)
    } else {
        return .error("Invalid integer")
    }
}

public let string: Decoder<String> = { json in
    if let value = json.string {
        return .ok(value)
    } else {
        return .error("Invalid string")
    }
}

public let bool: Decoder<Bool> = { json in
    if let value = json.bool {
        return .ok(value)
    } else {
        return .error("Invalid boolean")
    }
}

public let double: Decoder<Double> = { json in
    if let value = json.double {
        return .ok(value)
    } else {
        return .error("Invalid double")
    }
}
