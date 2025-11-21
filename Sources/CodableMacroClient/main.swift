import CodableMacro
import Foundation

@CodableModel
struct User: Codable {
    @CKey("name1") let name: String
    let age: Int
    @Default(4) let cls: Int?
}

let json = """
{
    "name1": "zhangsan",
    "age": 18
}
""".data(using: .utf8)!

do {
    let d = JSONDecoder()
    let user = try d.decode(User.self, from: json)
    print("--- user = \(user)")
} catch {
    print("--- error = \(error)")
}
