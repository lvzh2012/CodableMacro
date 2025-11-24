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

if let user = try? User.rk.decode(from: json) {
    print("---- user = \(user)")
}

do {
    let user = try User.rk.decode(from: json)
    print("--- user = \(user)")
} catch {
    print("--- error = \(error)")
}
