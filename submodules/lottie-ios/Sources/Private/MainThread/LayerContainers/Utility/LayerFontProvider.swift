







import Foundation


final class LayerFontProvider {

  

  init(fontProvider: AnimationFontProvider) {
    self.fontProvider = fontProvider
    textLayers = []
    reloadTexts()
  }

  

  private(set) var textLayers: [TextCompositionLayer]

  var fontProvider: AnimationFontProvider {
    didSet {
      reloadTexts()
    }
  }

  func addTextLayers(_ layers: [TextCompositionLayer]) {
    textLayers += layers
  }

  func reloadTexts() {
    textLayers.forEach {
      $0.fontProvider = fontProvider
    }
  }
}
