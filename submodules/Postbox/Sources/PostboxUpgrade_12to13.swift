import Foundation

func postboxUpgrade_12to13(metadataTable: MetadataTable, valueBox: ValueBox, progress: (Float) -> Void) {
    
    valueBox.removeAllFromTable(ValueBoxTable(id: 30, keyType: .binary, compactValuesOnCreation: true))
    
    
    valueBox.removeAllFromTable(ValueBoxTable(id: 31, keyType: .binary, compactValuesOnCreation: false))
    
    metadataTable.setUserVersion(13)
}
