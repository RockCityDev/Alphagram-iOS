import Foundation
import UIKit
import TBWeb3Core

public struct TBItemListLabelsContentLayoutConfig {
    
    public enum ViewType: Int {
        case normal 
        case special 
        case text 
    }
    
    public struct CaculateContext {
        var row: Int 
        var column: Int 
        var maxX: CGFloat 
        var itemSize: CGSize 
    }
    
    public var minimumLineSpacing: CGFloat
    public var minimumInteritemSpacing: CGFloat
    public var insetForSection: UIEdgeInsets
    
    public var viewType: ViewType
    public var font: UIFont
    public var itemInset: UIEdgeInsets
    
    public init(minimumLineSpacing: CGFloat = 8,
                minimumInteritemSpacing: CGFloat = 8,
                insetForSection: UIEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
                viewType: ViewType = .normal,
                font: UIFont = .systemFont(ofSize: 14, weight: .regular),
                itemInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)) {
        self.minimumLineSpacing = minimumLineSpacing
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.insetForSection = insetForSection
        self.viewType = viewType
        self.font = font
        self.itemInset = itemInset
    }
    
    public func contentSize(items:[TBWeb3GroupInfoEntry.Tag], maxWidth: CGFloat = UIScreen.main.bounds.width) ->CGSize {
        let infos = self.rowsInfo(items: items)
        guard let lastInfo = infos.last else {
            return CGSize(width: maxWidth, height: 0)
        }
        let rows:CGFloat = CGFloat(lastInfo.row) + 1.0
        let height:CGFloat =  self.insetForSection.top + lastInfo.itemSize.height * rows + (rows - 1) * self.minimumLineSpacing + self.insetForSection.bottom
        return CGSize(width: maxWidth, height: height)
    }
    
    
    public func rowsInfo(items:[TBWeb3GroupInfoEntry.Tag], maxWidth: CGFloat = UIScreen.main.bounds.width)-> [CaculateContext] {
        var rowsInfo = [CaculateContext]()
        var currentContext = CaculateContext(row: 0, column: 0, maxX: 0, itemSize: CGSize.zero)
        for (_, item) in items.enumerated() {
            currentContext.itemSize = item.itemSize(config: self)
            if currentContext.column == 0 {
                currentContext.maxX = self.insetForSection.left + currentContext.itemSize.width
                rowsInfo.append(CaculateContext(row: currentContext.row, column: currentContext.column, maxX: currentContext.maxX, itemSize: currentContext.itemSize))
                currentContext.column += 1
            }else{
                let willMaxX = currentContext.maxX +  self.minimumInteritemSpacing + currentContext.itemSize.width + self.insetForSection.right
                if willMaxX > maxWidth {
                    currentContext.row += 1
                    currentContext.column = 0
                    currentContext.maxX = self.insetForSection.left + currentContext.itemSize.width
                    rowsInfo.append(CaculateContext(row: currentContext.row, column: currentContext.column, maxX: currentContext.maxX, itemSize: currentContext.itemSize))
                    currentContext.column += 1
                }else{
                    currentContext.maxX = currentContext.maxX +  self.minimumInteritemSpacing + currentContext.itemSize.width
                    rowsInfo.append(CaculateContext(row: currentContext.row, column: currentContext.column, maxX: currentContext.maxX, itemSize: currentContext.itemSize))
                    currentContext.column += 1
                }
            }
           
        }
        return rowsInfo
    }
    
}

extension TBWeb3GroupInfoEntry.Tag {
    
    public func itemSize(config: TBItemListLabelsContentLayoutConfig) -> CGSize {
        let textWidth = self.name.tb_widthForComment(fontSize: config.font.pointSize, height: 17)
        let textHeight = self.name.tb_heightForComment(fontSize: config.font.pointSize, width: 1000)
        switch config.viewType {
        case .normal, .special:
            let totalWidth = config.itemInset.left + textWidth + 4 + 17 + config.itemInset.right
            let totalHeight = config.itemInset.top +  textHeight + config.itemInset.bottom
            return CGSize(width: totalWidth, height: totalHeight)
        case .text:
            let totalWidth = config.itemInset.left + textWidth + config.itemInset.right
            let totalHeight = config.itemInset.top +  textHeight + config.itemInset.bottom
            return CGSize(width: totalWidth, height: totalHeight)
        }
    }
}

