import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum WithPreviewVariantError: Error, CustomStringConvertible {
  case declNotModelClass
  case declContainsMembersOtherThanVarAndInit
  case initDeclMustComeAfterAllVarDecl
  case varDeclTooComplex(String)
  case varDeclMustSpecifyType(String)
  
  var description: String {
    switch self {
    case .declNotModelClass: "The decorated type is not an @Model class."
    case .declContainsMembersOtherThanVarAndInit: "The decorated type can't contain any member other than variable declarations or initializer; Consider put them in an extension."
    case .initDeclMustComeAfterAllVarDecl: "The initializer must be defined after any variable declarations."
    case .varDeclTooComplex(let context): "The variable declaration of `\(context)` is too complex; It must be in a shape of `var fieldName: SomeType`."
    case .varDeclMustSpecifyType(let context): "The variable declaration of `\(context)` must explicitly declare a type."
    }
  }
}

class InitDeclPreviewTypeRewriter: SyntaxRewriter {
  var rewriteTypes: Set<String>
  
  init(rewriteTypes: Set<String>) {
    self.rewriteTypes = rewriteTypes
  }
  
  override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
    do {
      let (beforeType, type, afterType) = try unwrapRelationshipType("", node.type, "")
      if rewriteTypes.contains(type) {
        let previewType = "Preview\(type)"
        let fullPreviewType = "\(beforeType)\(previewType)\(afterType)"
        let newNode = node.with(\.type, .init(stringLiteral: fullPreviewType))
        return super.visit(newNode)
      } else {
        return super.visit(node)
      }
    } catch {
      return super.visit(node)
    }
  }
}

func unwrapRelationshipType(_ beforeType: String = "", _ type: TypeSyntax, _ afterType: String = "") throws -> (String, String, String) {
  if let type = type.as(IdentifierTypeSyntax.self) {
    return (beforeType, type.name.text, afterType)
  } else if let type = type.as(OptionalTypeSyntax.self) {
    return try unwrapRelationshipType(beforeType, type.wrappedType, "?\(afterType)")
  } else if let type = type.as(ArrayTypeSyntax.self) {
    return try unwrapRelationshipType("\(beforeType)[", type.element, "]\(afterType)")
  } else {
    throw WithPreviewVariantError.varDeclTooComplex(type.trimmedDescription)
  }
}

public struct WithPreviewVariantMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    guard
      let originalClassDecl = declaration.as(ClassDeclSyntax.self),
      originalClassDecl.attributes.contains(where: { attr in
        attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Model"
      })
    else {
      throw WithPreviewVariantError.declNotModelClass
    }
    
    let className = originalClassDecl.name.text
    let protocolName = "\(className)Protocol"
    let previewName = "Preview\(className)"
    
    let memberCount = originalClassDecl.memberBlock.members.count
    
    var protocolMembers: [String] = []
    var structMembers: [String] = []
    protocolMembers.reserveCapacity(memberCount)
    structMembers.reserveCapacity(memberCount)
    
    var protocolAssociatedTypes: Set<String> = []
    var typesToBeReplacedWithPreviewType: Set<String> = []
    
    var metInitDecl = false
    for potentialMember in originalClassDecl.memberBlock.members {
      if let varDecl = potentialMember.decl.as(VariableDeclSyntax.self) {
        guard !metInitDecl else {
          throw WithPreviewVariantError.initDeclMustComeAfterAllVarDecl
        }
        
        let isRelationship = varDecl.attributes.contains(where: { attr in
          attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Relationship"
        })
        
        let bindings = varDecl.bindings
        var protocolBindings: [String] = []
        var structBindings: [String] = []
        for binding in bindings {
          guard
            let binding = binding.as(PatternBindingSyntax.self),
            let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
          else {
            throw WithPreviewVariantError.varDeclTooComplex(binding.trimmedDescription)
          }
          guard let typeSyntax = binding.typeAnnotation?.type else {
            throw WithPreviewVariantError.varDeclMustSpecifyType(binding.trimmedDescription)
          }
          
          if isRelationship {
            let (beforeType, type, afterType) = try unwrapRelationshipType("", typeSyntax, "")
            let fullType = "\(beforeType)\(type)\(afterType)"
            
            let correspondingProtocol = "\(type)Protocol"
            protocolAssociatedTypes.insert("associatedtype \(type): \(correspondingProtocol)")
            
            protocolBindings.append("\(name): \(fullType) { get set }")
            
            let correspondingPreviewType = "Preview\(type)"
            typesToBeReplacedWithPreviewType.insert(type)
            let fullPreviewType = "\(beforeType)\(correspondingPreviewType)\(afterType)"
            structBindings.append("\(name): \(fullPreviewType)\(binding.initializer?.description ?? "")")
          } else {
            protocolBindings.append("\(name): \(typeSyntax) { get set }")
            structBindings.append("\(name): \(typeSyntax)\(binding.initializer?.description ?? "")")
          }
        }
        
        let protocolMemberString = "var \(protocolBindings.joined(separator: ", "))"
        protocolMembers.append(protocolMemberString)
        
        let structMemberString = "\(varDecl.bindingSpecifier.text) \(structBindings.joined(separator: ", "))"
        structMembers.append(structMemberString)
      } else if let initDecl = potentialMember.decl.as(InitializerDeclSyntax.self) {
        let rewriter = InitDeclPreviewTypeRewriter(rewriteTypes: typesToBeReplacedWithPreviewType)
        let newInitDecl = rewriter.rewrite(initDecl)
        structMembers.append(newInitDecl.description)
        metInitDecl = true
      } else {
        throw WithPreviewVariantError.declContainsMembersOtherThanVarAndInit
      }
    }
    
    let protocolDeclString = """
    protocol \(protocolName) {
      \(protocolAssociatedTypes.joined(separator: "\n"))
    
      \(protocolMembers.joined(separator: "\n"))
    }
    """
    
    let structDeclString = """
    struct \(previewName): \(protocolName) {
      \(structMembers.joined(separator: "\n"))
    }
    """
    
    return [
      DeclSyntax(stringLiteral: protocolDeclString),
      DeclSyntax(stringLiteral: structDeclString)
    ]
  }
}

@main
struct WithPreviewVariantPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    WithPreviewVariantMacro.self,
  ]
}
