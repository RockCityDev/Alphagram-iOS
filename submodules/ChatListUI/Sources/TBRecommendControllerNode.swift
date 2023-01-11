
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import SwiftSignalKit
import TBLanguage
import MJRefresh
import SnapKit
import SDWebImage

class TBRecommendCell: UITableViewCell {
    
    let iconV: UIImageView
    let titleV: UILabel
    let tagsV: UILabel
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.iconV = UIImageView()
        self.titleV = UILabel()
        self.tagsV = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white
        self.contentView.addSubview(self.iconV)
        self.contentView.addSubview(self.titleV)
        self.contentView.addSubview(self.tagsV)
        self.layoutSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutSubview() {
        self.iconV.layer.cornerRadius = 26
        self.iconV.layer.masksToBounds = true
        self.iconV.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(25)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(52)
        }
        self.titleV.textColor = UIColor.black
        self.titleV.font = Font.medium(17)
        self.titleV.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(91)
            make.top.equalToSuperview().offset(13)
            make.trailing.equalToSuperview().offset(-25)
        }
        self.tagsV.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.87)
        self.tagsV.font = Font.regular(16)
        self.tagsV.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(91)
            make.bottom.equalToSuperview().offset(-11)
            make.trailing.equalToSuperview().offset(-25)
        }
        let line = UIView()
        line.backgroundColor = UIColor(hexString: "#80EBEBEB")
        self.contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(91)
            make.trailing.equalToSuperview().offset(-15)
            make.height.equalTo(0.5)
        }
    }
    
}


class TBRecommendControllerNode: ASDisplayNode {

    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let tableView: UITableView
    
    var itemClickEvent: ((_ link: String) -> Void)?
    
    let pagePromise: ValuePromise<Int>
    private var _page: Int
    
    private var items = [TBRecommendItem]()
    
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.tableView = UITableView(frame: .zero, style: .plain)
        self._page = 0
        self.pagePromise = ValuePromise(0)
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .never
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.estimatedRowHeight = 0
        self.tableView.estimatedSectionHeaderHeight = 0
        self.tableView.estimatedSectionFooterHeight = 0
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.white
        self.tableView.register(TBRecommendCell.self, forCellReuseIdentifier: String(describing: TBRecommendCell.self))
        self.view.addSubview(tableView)
        self.tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [unowned self] in
            self._page = 1
            self.tableView.mj_footer?.state = .idle
            self.pagePromise.set(self._page)
        })
        self._page = 1
        self.pagePromise.set(self._page)
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let y = (layout.statusBarHeight ?? 20) + 44
        self.tableView.frame = CGRect(x: 0, y: y, width: layout.size.width, height: layout.size.height - y)
    }
    
    func iWillUseChineseAndShuaXinList(_ items: [TBRecommendItem]) {
        if self._page == 1 {
            self.items = items
            self.tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [unowned self] in
                self._page += 1
                self.pagePromise.set(self._page)
            })
        } else {
            self.items.append(contentsOf: items)
        }
        self.tableView.reloadData()
    }
    
    func endRefresh(_ isNoMoreData: Bool = false) {
        if isNoMoreData {
            self.tableView.mj_footer?.endRefreshingWithNoMoreData()
        } else {
            self.tableView.mj_footer?.endRefreshing()
        }
        self.tableView.mj_header?.endRefreshing()
    }
    
}


extension TBRecommendControllerNode: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TBRecommendCell.self)) as! TBRecommendCell
        if indexPath.row < self.items.count {
            let item = self.items[indexPath.row]
            cell.iconV.sd_setImage(with: URL(string: item.avatar ?? ""))
            cell.titleV.text = item.chat_title
            cell.tagsV.text = "\(item.follows) · \(item.online)"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row < self.items.count {
            let item = self.items[indexPath.row]
            if let event = self.itemClickEvent, let link = item.chat_link {
                event(link)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
