// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that provides a default value for a property when decoding fails or is missing.
/// Usage: @Default(value) var name: Type
@attached(peer)
public macro Default<T>(_ value: T) = #externalMacro(module: "CodableMacroMacros", type: "DefaultMacro")

/// A macro that specifies a custom JSON key for a property.
/// Usage: @CKey("json_key") var name: Type
@attached(peer)
public macro CKey(_ key: String) = #externalMacro(module: "CodableMacroMacros", type: "CKeyMacro")

/// A macro that generates `init(from: Decoder)`, `encode(to: Encoder)` and `CodingKeys` for a struct/class,
/// handling default values specified by `@Default`.
/// handling values specified key by `@CKey`.
@attached(member, names: named(init(from:)), named(encode(to:)), named(CodingKeys))
public macro CodableModel() = #externalMacro(module: "CodableMacroMacros", type: "CodableModelMacro")
