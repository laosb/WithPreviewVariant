@attached(
  peer,
  names:
    suffixed(Protocol),
    prefixed(Preview),
    prefixed(_Observable),
    prefixed(Observable),
    prefixed(ObservablePreview)
)
public macro WithPreviewVariant() = #externalMacro(module: "WithPreviewVariantMacros", type: "WithPreviewVariantMacro")

@attached(peer)
public macro InverseRelationship() = #externalMacro(module: "WithPreviewVariantMacros", type: "InverseRelationshipMacro")
