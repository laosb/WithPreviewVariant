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
