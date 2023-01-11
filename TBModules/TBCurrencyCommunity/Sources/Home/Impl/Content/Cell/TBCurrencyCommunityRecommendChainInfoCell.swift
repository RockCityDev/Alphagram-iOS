






import UIKit
import SnapKit
import TBWeb3Core
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import SwiftSignalKit
import TBDisplay

typealias ChainButton = TBWeb3ConfigEntry.Chain.Button

fileprivate func toolItems(buttons: [ChainButton]) -> [TBToolItem<ChainButton>] {
    var rel = [TBToolItem<ChainButton>]()
    for button in buttons {
        let d: TBToolItem<ChainButton> = TBToolItem<ChainButton>(type: button, title: button.name, iconName: button.icon_link, color: UIColor.white)
        rel.append(d)
    }
    return rel
}

public class TBCurrencyCommunityRecommendChainInfoCell: UICollectionViewCell {
    
    let unitPriceLabel: UILabel
    let amplitudeLabel: UILabel
    let amplitudeImageV: UIImageView
    let timeIntervalLabel: UILabel
    let chainLabel: UILabel
    let currencyLabel: UILabel
    
    private var chain: TBWeb3ConfigEntry.Chain?
    private var items = [TBToolItem<ChainButton>]()
    private var itemNodes = [TBToolItemNode<ChainButton>]()
    
    var buttonItemEvent: ((ChainButton)->())?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.unitPriceLabel = UILabel()
        self.amplitudeLabel = UILabel()
        self.amplitudeImageV = UIImageView()
        self.timeIntervalLabel = UILabel()
        self.chainLabel = UILabel()
        self.currencyLabel = UILabel()
    
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.addSubviews()
        self.batchMakeConstraints()
        
    }
    
    func addSubviews() {
        self.unitPriceLabel.font = Font.bold(32)
        self.unitPriceLabel.textColor = UIColor(hexString: "#FF000000")
        self.unitPriceLabel.numberOfLines = 1
        self.contentView.addSubview(self.unitPriceLabel)
        
        self.amplitudeLabel.font = Font.medium(16)
        self.amplitudeLabel.textColor = UIColor(hexString: "#FFF06464")
        self.amplitudeLabel.numberOfLines = 1
        self.contentView.addSubview(self.amplitudeLabel)
        
        self.contentView.addSubview(self.amplitudeImageV)
        
        self.timeIntervalLabel.font = Font.regular(12)
        self.timeIntervalLabel.textColor = UIColor(hexString: "#FF828282")
        self.timeIntervalLabel.text = "24h"
        self.timeIntervalLabel.numberOfLines = 1
        self.contentView.addSubview(self.timeIntervalLabel)
        
        self.chainLabel.font = Font.medium(13)
        self.chainLabel.textColor = UIColor(hexString: "#FF333333")
        self.chainLabel.numberOfLines = 1
        self.contentView.addSubview(self.chainLabel)
        
        self.currencyLabel.font = Font.medium(10)
        self.currencyLabel.backgroundColor = UIColor(hexString: "#FFEAEAEA")
        self.currencyLabel.layer.cornerRadius = 4.0
        self.currencyLabel.layer.masksToBounds = true
        self.currencyLabel.textColor = UIColor(hexString: "#FF000000")
        self.currencyLabel.numberOfLines = 1
        self.contentView.addSubview(self.currencyLabel)
        
    }
    
    func batchMakeConstraints() {
        self.unitPriceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(28)
        }
        
        self.amplitudeLabel.snp.makeConstraints { make in
            make.top.equalTo(self.unitPriceLabel.snp.top)
            make.leading.equalTo(self.unitPriceLabel.snp.trailing).offset(12)
            make.height.equalTo(16)
        }
        
        self.amplitudeImageV.snp.makeConstraints { make in
            make.centerY.equalTo(self.amplitudeLabel)
            make.leading.equalTo(self.amplitudeLabel.snp.trailing).offset(2)
            make.height.width.equalTo(16)
        }
        
        self.timeIntervalLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self.unitPriceLabel.snp.bottom)
            make.leading.equalTo(self.unitPriceLabel.snp.trailing).offset(12)
            make.height.equalTo(12)
        }
        
        self.chainLabel.snp.makeConstraints { make in
            make.top.equalTo(self.unitPriceLabel.snp.bottom).offset(11)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(16)
        }
        
        self.currencyLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.chainLabel)
            make.leading.equalTo(self.chainLabel.snp.trailing).offset(4)
            make.height.equalTo(14)
        }
        
    }
    
    func buttonItemClick(button: ChainButton) {
        self.buttonItemEvent?(button)
    }
    
    func reloadCellByChain(by chain: TBWeb3ConfigEntry.Chain, coinPriceSignal: Signal<CurrencyPrice, NoError>) {
        if chain == self.chain { return }
        self.chainLabel.text = chain.name
        self.currencyLabel.text = " \(chain.main_currency_name) "
        
        self.items.removeAll()
        for node in self.itemNodes {
            node.removeFromSupernode()
        }
        self.itemNodes.removeAll()
        
        self.items = toolItems(buttons: chain.button)
        if self.items.count > 0 {
            let width = UIScreen.main.bounds.width - 20 - 10 * CGFloat(self.items.count - 1)
            let eachWidth = width / CGFloat(self.items.count)
            let theme = TBItemNodeTheme(itemsize: CGSize(width: eachWidth, height: 74), bgSize: CGSize(width: 35, height: 35), imageSize: CGSize(width: 35, height: 35))
            for (index, item) in self.items.enumerated() {
                let itemNode = TBToolItemNode<ChainButton>(itemTheme: theme)
                itemNode.updateNodeBy(item)
                itemNode.clickEvent = {[weak self] button in
                    self?.buttonItemClick(button: button)
                }
                itemNode.frame = CGRect(x: 10 + (eachWidth + 10) * CGFloat(index), y: 120, width: eachWidth, height: 74)
                self.itemNodes.append(itemNode)
                self.contentView.addSubnode(itemNode)
            }
        }
        
        let _ = coinPriceSignal.start(next: { price in
            self.unitPriceLabel.text = "$" + price.usd
            let isRase = NSDecimalNumber(string: price.usd_24h_change).compare(NSNumber(value: 0)) != .orderedAscending
            let color = isRase ? UIColor(hexString: "#FF32C481")! : UIColor(hexString: "#FFF06464")!
            let image = isRase ? UIImage(named: "TBWallet/icon_triangle_up_gtoup") : UIImage(named: "TBWallet/icon_triangle_down_gtoup")
            image?.withTintColor(color, renderingMode: .alwaysTemplate)
            self.amplitudeLabel.textColor = color
            let format = NumberFormatter()
            format.maximumFractionDigits = 2
            if let usd = format.string(from: NSDecimalNumber(string: price.usd_24h_change)) {
                self.amplitudeLabel.text = usd + "%"
            }
            self.amplitudeImageV.tintColor = color
            self.amplitudeImageV.image = image
        })
    }
}

