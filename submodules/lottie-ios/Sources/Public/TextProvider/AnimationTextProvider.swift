






import Foundation




public protocol AnimationTextProvider: AnyObject {
  func textFor(keypathName: String, sourceText: String) -> String
}




public final class DictionaryTextProvider: AnimationTextProvider {

  

  public init(_ values: [String: String]) {
    self.values = values
  }

  

  public func textFor(keypathName: String, sourceText: String) -> String {
    values[keypathName] ?? sourceText
  }

  

  let values: [String: String]
}




public final class DefaultTextProvider: AnimationTextProvider {

  

  public init() {}

  

  public func textFor(keypathName _: String, sourceText: String) -> String {
    sourceText
  }
}
