import Vapor
import Leaf

public func configure(
  _ config: inout Config,
  _ env: inout Environment,
  _ services: inout Services
  ) throws {

  // Configure the rest of your application here
  try services.register(LeafProvider())
  config.prefer(LeafRenderer.self, for: TemplateRenderer.self)
}
