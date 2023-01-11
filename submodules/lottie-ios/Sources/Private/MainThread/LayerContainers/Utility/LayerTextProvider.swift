






import Foundation


final class LayerTextProvider {

  

  init(textProvider: AnimationTextProvider) {
    self.textProvider = textProvider
    textLayers = []
    reloadTexts()
  }

  

  private(set) var textLayers: [TextCompositionLayer]

  var textProvider: AnimationTextProvider {
    didSet {
      reloadTexts()
    }
  }

  func addTextLayers(_ layers: [TextCompositionLayer]) {
    textLayers += layers
  }

  func reloadTexts() {
    textLayers.forEach {
      $0.textProvider = textProvider
    }
  }
}
