import Vapor
import Leaf

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
  _ config: inout Config,
  _ env: inout Environment,
  _ services: inout Services
  ) throws {

  // Register Leaf as the default templating engine.
  try services.register(LeafProvider())
  config.prefer(LeafRenderer.self, for: TemplateRenderer.self)
}
