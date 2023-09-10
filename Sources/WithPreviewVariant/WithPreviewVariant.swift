@attached(
  peer,
  names: suffixed(Protocol), suffixed(ObservableProtocol), prefixed(Preview), prefixed(ObservablePreview)
)
public macro WithPreviewVariant() = #externalMacro(module: "WithPreviewVariantMacros", type: "WithPreviewVariantMacro")
