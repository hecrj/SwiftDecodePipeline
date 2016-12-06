# SwiftDecodePipeline

[![CI Status](http://img.shields.io/travis/hecrj/SwiftDecodePipeline.svg?style=flat)](https://travis-ci.org/hecrj/SwiftDecodePipeline)
[![Version](https://img.shields.io/cocoapods/v/SwiftDecodePipeline.svg?style=flat)](http://cocoapods.org/pods/SwiftDecodePipeline)
[![License](https://img.shields.io/cocoapods/l/SwiftDecodePipeline.svg?style=flat)](http://cocoapods.org/pods/SwiftDecodePipeline)
[![Platform](https://img.shields.io/cocoapods/p/SwiftDecodePipeline.svg?style=flat)](http://cocoapods.org/pods/SwiftDecodePipeline)

A library for building JSON decoders using the pipeline `(|>)` operator and plain function calls. Inspired by
[elm-decode-pipeline](https://github.com/NoRedInk/elm-decode-pipeline).

## Motivation

As a newcomer to Swift I wasn't entirely convinced by the JSON decoding libraries out there. After trying Elm, I was hoping something
simple and mostly functional would be available. 

[Argo][argo] got my attention. While it looked really close to what I wanted, it forces you to implement a `decode` method in your types.
This allows [Argo][argo] to automatically decode any type that implements the `Decodable` protocol.
But, this approach isn't flexible. It ties **one** (and only one) decoder to a specific type, **forever**. What if
we want to decode the responses of different APIs into the same type? What if some endpoint doesn't return the data in the exact same way?
Sounds familiar? Besides, [Argo][argo] uses many different infix operators (`<^>`, `<*>`, `<|`, `<||`) that make the decoder definitions hard to
understand and reason about.

My take is that decoders should be pure functions that live independently from types. They accept some data (JSON, for now) and produce either an error
or an instance of some type. Decoders should be easy to compose and reuse, and all it should be needed for that is one simple infix operator:
the pipeline `(|>)`. This approach is really well implemented in [elm-decode-pipeline][edp], an [Elm][elmlang] library, producing simple, readable and
reusable decoders.

**SwiftDecodePipeline** tries to bring the spirit of [elm-decode-pipeline][edp] into Swift.

## Example

Let's say that we have this type:

```swift
struct User {
    let name: String
    let surname: String
    let image: String?
    let score: Int
    let sports: [String]
    let role: String
}
```

And we want to decode the data returned by some API endpoint `/users` that looks like this:

```json
[
    {
        "uuid": "...",
        "name": "John",
        "last_name": "Doe",
        "image": null,
        "sports": ["basketball", "tennis"],
        "score": 5
    }
]
```

Then, we can write a `Decoder<User>` for that endpoint easily:

```swift
let decodeUser: Decoder<User> =
    decode(User.init)
        |> required("name", string)
        |> required("last_name", string)
        |> optional("image", string)
        |> required("score", int)
        |> required("sports", array(string))
        |> hardcoded("athlete")
```

Now we can decode the response:

```swift
let data: String!

// We make a request to /users and obtain the JSON here...

let result = decodeJSON(data, with: array(decodeUser))

switch result {
case .error(let error): print("Invalid format: \(error)") // error describes the decoding error
case .ok(let users): doSomething(with: users) // users has type [User] :D
}
````

In the example above, `data` is a `String`. However, the `decode` function supports different types for the first parameter to suit your needs.
The next section describes the different data types that can be decoded using this library.

Notice how easy it is to transform and reuse decoders. In this case, our `decodeUser` is able to decode a single user, but we want to decode a list of users.
Thus, we end up using `array(decodeUser)` to transform our `Decoder<User>` into a `Decoder<[User]>`. A `Decoder<Type>` returns either `.error(String)`
when the format is invalid, or `.ok(Type)` when the input was decoded sucessfully.


## Available functions
### `decodeJSON(json, with: decoder)`

It allows to use decoders for JSON decoding in a convenient way. Right now, there are 3 different `decodeJSON` definitions. Each one of them accepts
JSON in a different form: `Data`, `String` and `Any`.

The `Any` definition is there to [support Alamofire response data](#library-support).

### Primitives

Primitives are decoders by themselves. They decode JSON values into Swift values.

```swift
let string: Decoder<String> 
let bool:   Decoder<Bool>
let int:    Decoder<Int>
let double: Decoder<Double>
```

### Modifiers

A modifier is a function that may take some configuration parameters and returns a function that can take a decoder and return a brand new decoder
with some additional behaviour.

In this section, the syntax `<modifier>(<configParams>)` is used to describe the different modifiers.

#### `required(String, Decoder<A>)` and `optional(String, Decoder<A>)`

`required` extracts a field from a JSON object and decodes its value into an `A`, failing if the field does not exist or it is `null`.
`optional` does the same while allowing the field to be missing or `null`, thus decoding into an `A?`.

```swift
struct User {
    let name: String
    let image: String?
}

let decodeUser: Decoder<User> =
    decode(User.init)
        |> required("name", string)
        |> optional("image", string)
```

#### `array`
It decodes a JSON array.

```swift
struct Post {
    // ...
    let authors: [User]
    // ...
}

let decodePost: Decoder<Post> =
    decode(Post.init)
        //...
        |> required("authors", decodeUser |> array)
        // We could use array(decodeUser), they are equivalent
        // ...
```

#### `hardcoded(A)`

It always returns the provided value, independently of the JSON data. It is useful to hardcode data in the decoding pipeline.

```swift
let decodeMockedUser: Decoder<User> =
    decode(User.init)
        |> hardcoded("some-id")
        |> hardcoded("John")
        |> hardcoded("Doe")
        // ...
```

#### `map((A) -> B)`

It transforms a decoded value from `A` to `B`.

```swift
let decodeLowercasedString: Decoder<String> = string |> map { $0.lowercased }
```

## Library support

### Alamofire

This library can be used with [Alamofire][alamofire] easily:

```swift
Alamofire.request("https://example.com/users").validate().responseJSON { response in
    switch response.result {
    case .success(let data):
        // We want to decode a list of users, so we use array
        let decodingResult = decodeJSON(data, with: array(decodeUser))

        switch decodingResult {
        case .error(let error): print("Invalid format: \(error)") // error describes the decoding error
        case .ok(let users): doSomething(with: users) // users has type [User]
        }
    // Handle request error here...
    }
}
```

### SwiftyJSON

This library uses [SwiftyJSON](swiftyjson) internally. You should be able to decode `JSON` types using decoders
directly:

```swift
let json: JSON!
let result = decodeUser(json)
```

## Installation

SwiftDecodePipeline is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftDecodePipeline'
```

## Author

Héctor Ramón Jiménez

## License

SwiftDecodePipeline is available under the MIT license. See the LICENSE file for more info.

## Contributing

1. Fork the repository.
2. Make your changes, tests will be appreciated.
3. Open a Pull Request in this repository.

## Special mentions (and thanks)
* [SwiftyJSON][swiftyjson], as it is really easy to use and this library uses it internally.
* [Curry][curry], another cool library that is used behind the scenes.
* [Argo][argo]
* [Elm][elmlang]


[argo]: https://github.com/thoughtbot/Argo
[edp]: https://github.com/NoRedInk/elm-decode-pipeline
[alamofire]: https://github.com/Alamofire/Alamofire
[swiftyjson]: https://github.com/SwiftyJSON/SwiftyJSON
[curry]: https://github.com/thoughtbot/Curry
[elmlang]: http://elm-lang.org
