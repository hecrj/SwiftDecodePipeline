//
//  SwiftDecodePipeline.swift
//  Pods
//
//  Created by Héctor Ramón on 05/12/2016.
//
//

import Foundation
import Curry
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

// Decoding functions
public func decodeJSON<T>(_ json: String, with decoder: Decoder<T>) -> Result<String, T> {
    if let jsonFromString = json.data(using: .utf8, allowLossyConversion: false) {
        return decodeJSON(jsonFromString, with: decoder)
    } else {
        return .error("String could not be converted to JSON data")
    }
}

public func decodeJSON<T>(_ json: Data, with decoder: Decoder<T>) -> Result<String, T> {
    return decoder(JSON(data: json))
}

public func decodeJSON<T>(_ json: Any, with decoder: Decoder<T>) -> Result<String, T> {
    return decoder(JSON(json))
}

// Composable functions
public func decode<A>(_ value: A) -> Decoder<A> {
    return { json in return .ok(value) }
}

public func decode<A, B>(_ function: @escaping (A) -> B) -> Decoder<(A) -> B> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C>(_ function: @escaping (A, B) -> C) -> Decoder<(A) -> (B) -> C> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D>(_ function: @escaping (A, B, C) -> D) -> Decoder<(A) -> (B) -> (C) -> D> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E>(_ function: @escaping (A, B, C, D) -> E) -> Decoder<(A) -> (B) -> (C) -> (D) -> E> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F>(_ function: @escaping (A, B, C, D, E) -> F) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> F> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F, G>(_ function: @escaping (A, B, C, D, E, F) -> G) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> G> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F, G, H>(_ function: @escaping (A, B, C, D, E, F, G) -> H) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> H> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F, G, H, I>(_ function: @escaping (A, B, C, D, E, F, G, H) -> I) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> (H) -> I> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F, G, H, I, J>(_ function: @escaping (A, B, C, D, E, F, G, H, I) -> J) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> (H) -> (I) -> J> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F, G, H, I, J, K>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J) -> K) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> (H) -> (I) -> (J) -> K> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F, G, H, I, J, K, L>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J, K) -> L) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> (H) -> (I) -> (J) -> (K) -> L> {
    return { json in return .ok(curry(function)) }
}

public func decode<A, B, C, D, E, F, G, H, I, J, K, L, M>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J, K, L) -> M) -> Decoder<(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> (H) -> (I) -> (J) -> (K) -> (L) -> M> {
    return { json in return .ok(curry(function)) }
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
    -> (@escaping Decoder<(A) -> B>) -> Decoder<B> {
        return custom(field(key, valDecoder))
}

public func at<A, B>(_ keys: [String], _ valDecoder: @escaping Decoder<A>) -> (@escaping Decoder<(A) -> B>) -> Decoder<B> {
    return custom { json in
        var nested = json
        
        for key in keys { nested = nested[key] }
        
        let result = valDecoder(nested)
        
        switch result {
        case .ok(_): return result
        case .error(let error): return .error(":at(\(keys.joined(separator: "."))):\(error)")
        }
    }
}

public func optional<A>(_ decoder: @escaping Decoder<A>) -> Decoder<A?> {
    return { json in
        let result = decoder(json)
        
        switch result {
        case .error(_): return .ok(nil)
        case .ok(let value): return .ok(value)
        }
    }
}

public func optional<A, B>(_ key: String, _ valDecoder: @escaping Decoder<A>)
    -> (@escaping Decoder<(A?) -> B>) -> Decoder<B> {
        let fieldDecoder = field(key, valDecoder)
        
        return custom(optional(fieldDecoder))
}

public func hardcoded<A, B>(_ value: A)
    -> (_ decoder: @escaping Decoder<(A) -> B>) -> Decoder<B> {
        return custom(decode(value))
}

public func map<A, B>(_ f: @escaping (A) -> B) -> (@escaping Decoder<A>) -> Decoder<B> {
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

public func field<A>(_ key: String, _ decoder: @escaping Decoder<A>) -> Decoder<A> {
    return { json in
        let result = decoder(json[key])
        
        switch result {
        case .ok(_): return result
        case .error(let error): return .error(":field(\(key)):\(error)")
        }
    }
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

public func custom<A, B>(_ valDecoder: @escaping Decoder<A>)
    -> (@escaping Decoder<(A) -> B>) -> Decoder<B> {
        return { decoder in
            return { json in
                let result = decoder(json)
                
                switch result {
                case .error(let error): return .error(error)
                case .ok(let aToB):
                    let valResult = valDecoder(json)
                    
                    switch valResult {
                    case .error(let error): return .error(error)
                    case .ok(let a):
                        return .ok(aToB(a))
                    }
                }
            }
        }
}

public func andThen<A, B>(mapper: @escaping (A) -> Decoder<B>) -> (@escaping Decoder<A>) -> Decoder<B> {
    return { decoder in
        return { json in
            let result = decoder(json)
            
            switch result {
            case .ok(let value): return mapper(value)(json)
            case .error(let error): return .error(error)
            }
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

public let isPresent: Decoder<Bool> = { json in
    return .ok(json.null == nil)
}
