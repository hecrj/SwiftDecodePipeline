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
the pipeline `(|>)`. This approach is really well implemented in [elm-decode-pipeline][edp], an Elm library, producing simple, readable and
reusable decoders.

`SwiftDecodePipeline` tries to bring the spirit of [elm-decode-pipeline][edp] into Swift.

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
        |> hardcode("athlete")
```

Now we can decode the response:

```swift
let json: String

// We make a request to /users and obtain the JSON here...

let result = decode(json, with: array(decodeUser))

switch result {
case .error(let error): print("Invalid format: \(error)") // error describes the decoding error
case .ok(let users): doSomething(with: users) // users has type [User] :D
}
````

In the example above, `json` is a `String`. However, the `decode` function supports different types for the first parameter to suit your needs.
The next section describes the different data types that can be decoded using this library.

Notice how easy is to transform and reuse decoders. In this case, our `decodeUser` is able to decode a single user, but we want to decode a list of users.
Thus, we end up using `array(decodeUser)` to transform our `Decoder<User>` into a `Decoder<[User]>`. A `Decoder<Type>` returns either `.error(String)`
when the format is invalid or doesn't meet the decoder restrictions, or `.ok(Type)` when the input was decoded sucessfully.


## Available functions
### Decode
The ...

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

`required` extracts a field from a JSON object and decodes its value into an `A`.
`optional` does the same, but if the field does not exist it returns `nil`, thus decoding into an `A?`.

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
        /...
        |> required("authors", decodeUser |> array) // You could use array(decodeUser), they are equivalent
```

#### `hardcode(A)`

It always returns the provided value, independently of the JSON. It is useful to hardcode data in the decoding pipline.

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
    case .success(let json):
        // We want to decode a list of users, so we use array
        let decodingResult = decode(json, array(decodeUser))

        switch decodingResult {
        case .error(let error): print("Invalid format: \(error)") // error describes the decoding error
        case .ok(let users): doSomething(with: users) // users has type [User]
        }
    // Handle request error here...
    }
}
```

### SwiftyJSON

This library uses [SwiftyJSON](swiftyjson) internally. You should be able to decode `JSON` types with the `decode` function
with no issues.

## Requirements

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


[argo]: https://github.com/thoughtbot/Argo
[edp]: https://github.com/NoRedInk/elm-decode-pipeline
[alamofire]: https://github.com/Alamofire/Alamofire
[swiftyjson]: https://gi
