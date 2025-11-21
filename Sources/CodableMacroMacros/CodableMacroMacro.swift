import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DefaultMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        print("---- \(node) \(declaration) \(context)")
        return []
    }
}

public struct CKeyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        print("---- \(node) \(declaration) \(context)")
        return []
    }
}

public struct CodableModelMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        var members: MemberBlockItemListSyntax
        var isClass = false
        var inheritanceClause: InheritanceClauseSyntax?
        
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            members = structDecl.memberBlock.members
            inheritanceClause = structDecl.inheritanceClause
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            members = classDecl.memberBlock.members
            isClass = true
            inheritanceClause = classDecl.inheritanceClause
        } else {
            return []
        }
        
            // Check if CodingKeys enum already exists
        var hasCodingKeys = false
        for member in members {
            if let enumDecl = member.decl.as(EnumDeclSyntax.self),
               enumDecl.name.text == "CodingKeys" {
                hasCodingKeys = true
                break
            }
        }
        
        var cases: [String] = []
        var initBody: [String] = []
        var encodeBody: [String] = []
        
        initBody.append("let container = try decoder.container(keyedBy: CodingKeys.self)")
        encodeBody.append("var container = encoder.container(keyedBy: CodingKeys.self)")
        
        for member in members {
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  let binding = variable.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = binding.typeAnnotation?.type
            else {
                continue
            }
            
                // Skip static properties
            if variable.modifiers.contains(where: { $0.name.text == "static" }) {
                continue
            }
            
                // Skip computed properties
            if let accessors = binding.accessorBlock?.accessors {
                if case .accessors(let accessorList) = accessors {
                        // If it has a 'get' accessor without 'set' or is a get-only protocol requirement (not relevant here but good to note)
                        // If it has explicit get, we skip unless it's observing
                    let hasGet = accessorList.contains(where: { $0.accessorSpecifier.text == "get" })
                    let hasSet = accessorList.contains(where: { $0.accessorSpecifier.text == "set" })
                    if hasGet && !hasSet {
                        continue
                    }
                } else if case .getter = accessors {
                        // Implicit getter: var x: Int { return 1 }
                    continue
                }
            }
            
                // Check for attributes
            var defaultValue: ExprSyntax? = nil
            var customKey: String? = nil
            
            for attribute in variable.attributes {
                if let attr = attribute.as(AttributeSyntax.self),
                   let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                   let args = attr.arguments?.as(LabeledExprListSyntax.self),
                   let firstArg = args.first {
                    
                    if attrName == "Default" {
                        defaultValue = firstArg.expression
                    } else if attrName == "CKey" {
                            // Extract string literal from expression
                        if let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text {
                            customKey = stringLiteral
                        }
                    }
                }
            }
            
                // If we are generating CodingKeys, we add a case for each property
            if !hasCodingKeys {
                if let key = customKey {
                    cases.append("case \(identifier) = \"\(key)\"")
                } else {
                    cases.append("case \(identifier)")
                }
            }
            
                // Determine base type (stripping optional)
            var baseType = type
            var isOptional = false
            if let optionalType = type.as(OptionalTypeSyntax.self) {
                baseType = optionalType.wrappedType
                isOptional = true
            }
            
            if let def = defaultValue {
                initBody.append("self.\(identifier) = try container.decodeIfPresent(\(baseType).self, forKey: .\(identifier)) ?? \(def)")
            } else {
                if isOptional {
                    initBody.append("self.\(identifier) = try container.decodeIfPresent(\(baseType).self, forKey: .\(identifier))")
                } else {
                    initBody.append("self.\(identifier) = try container.decode(\(baseType).self, forKey: .\(identifier))")
                }
            }
            
                // Encode logic
            if isOptional {
                encodeBody.append("try container.encodeIfPresent(self.\(identifier), forKey: .\(identifier))")
            } else {
                encodeBody.append("try container.encode(self.\(identifier), forKey: .\(identifier))")
            }
        }
        
        var generatedDecls: [DeclSyntax] = []
        
        if !hasCodingKeys {
            let codingKeysEnum = """
            enum CodingKeys: String, CodingKey {
                \(cases.map { $0 }.joined(separator: "\n    "))
            }
            """
            generatedDecls.append(DeclSyntax(stringLiteral: codingKeysEnum))
        }
        
            // Check inheritance for NSObject
        if isClass, let inheritanceClause = inheritanceClause {
            for type in inheritanceClause.inheritedTypes {
                if let typeName = type.type.as(IdentifierTypeSyntax.self)?.name.text, typeName == "NSObject" {
                    initBody.append("super.init()")
                    break
                }
            }
        }
        
        let initPrefix = isClass ? "required init" : "init"
        let initDecl = """
        \(initPrefix)(from decoder: Decoder) throws {
            \(initBody.joined(separator: "\n    "))
        }
        """
        generatedDecls.append(DeclSyntax(stringLiteral: initDecl))
        
        let encodeDecl = """
        func encode(to encoder: Encoder) throws {
            \(encodeBody.joined(separator: "\n    "))
        }
        """
        generatedDecls.append(DeclSyntax(stringLiteral: encodeDecl))
        
        return generatedDecls
    }
}

@main
struct CodableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DefaultMacro.self,
        CKeyMacro.self,
        CodableModelMacro.self,
    ]
}
