// https://github.com/Quick/Quick

import Quick
import Nimble
import SwiftDecodePipeline

class SwiftDecodePipelineSpec: QuickSpec {
    struct User {
        let name: String
        let surname: String
        let image: String?
        let sports: [String]
        let score: Int
        let role: Role
    }
    
    public enum Role {
        case admin, user
    }
    
    var users_json: String {
        return try! String(contentsOfFile: Bundle.init(for: SwiftDecodePipelineSpec.self).path(forResource: "users", ofType: "json")!)
    }
    
    override func spec() {
        describe("decoding valid json") {
            context("full decoder") {
                let decodeUser: Decoder<User> =
                    decode(User.init)
                        |> required("name", string)
                        |> required("last_name", string)
                        |> optional("image", string)
                        |> required("sports", array(string))
                        |> required("score", int)
                        |> hardcoded(.admin)
                
                it("is expected to succeed") {
                    let result: Result<String, [User]> = decodeJSON(self.users_json, with: array(decodeUser))
                    
                    switch result {
                    case .ok(let users):
                        expect(users.count).to(equal(2))
                        expect(users[0].name).to(equal("John"))
                        expect(users[0].image).to(beNil())
                        expect(users[1].sports).to(equal(["running"]))
                        
                    case .error(let error):
                        fail(error)
                    }
                }
            }
        }
    }
}
