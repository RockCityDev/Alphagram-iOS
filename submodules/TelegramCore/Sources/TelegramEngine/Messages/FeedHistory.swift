import Foundation
import Postbox
import SwiftSignalKit
import TelegramApi

private class FeedHistoryContextImpl {
    private let queue: Queue
    private let account: Account
    private let feedId: Int32
    private let userId: Int64
    
    private var currentHole: (MessageHistoryHolesViewEntry, Disposable)?
    
    struct State: Equatable {
        var messageIndices: [MessageIndex]
        var holeIndices: [MessageId.Namespace: IndexSet]
    }
    
    let state = Promise<State>()
    private var stateValue: State? {
        didSet {
            if let stateValue = self.stateValue {
                if stateValue != oldValue {
                    self.state.set(.single(stateValue))
                }
            }
        }
    }
    
    let maxReadOutgoingMessageId = Promise<MessageId?>()
    private var maxReadOutgoingMessageIdValue: MessageId? {
        didSet {
            if self.maxReadOutgoingMessageIdValue != oldValue {
                self.maxReadOutgoingMessageId.set(.single(self.maxReadOutgoingMessageIdValue))
            }
        }
    }

    private var maxReadIncomingMessageIdValue: MessageId?

    let unreadCount = Promise<Int>()
    private var unreadCountValue: Int = 0 {
        didSet {
            if self.unreadCountValue != oldValue {
                self.unreadCount.set(.single(self.unreadCountValue))
            }
        }
    }
    
    private var initialStateDisposable: Disposable?
    private var holesDisposable: Disposable?
    private var readStateDisposable: Disposable?
    private var updateInitialStateDisposable: Disposable?
    private let readDisposable = MetaDisposable()
    
    init(queue: Queue, account: Account, feedId: Int32, userId: Int64) {
        self.queue = queue
        self.account = account
        self.feedId = feedId
        self.userId = userId
        
        self.maxReadOutgoingMessageIdValue = nil
        self.maxReadOutgoingMessageId.set(.single(self.maxReadOutgoingMessageIdValue))

        self.maxReadIncomingMessageIdValue = nil

        self.unreadCountValue = 0
        self.unreadCount.set(.single(self.unreadCountValue))
        
        self.initialStateDisposable = (account.postbox.transaction { transaction -> State in
            return State(messageIndices: [], holeIndices: [Namespaces.Message.Cloud: IndexSet(integersIn: 2 ... 2)])
        }
        |> deliverOn(self.queue)).start(next: { [weak self] state in
            guard let strongSelf = self else {
                return
            }
            strongSelf.stateValue = state
            strongSelf.state.set(.single(state))
        })
        
        
        
        let userId = self.userId
        self.holesDisposable = (account.postbox.messageHistoryHolesView()
        |> map { view -> MessageHistoryHolesViewEntry? in
            for entry in view.entries {
                if entry.userId == userId {
                    return entry
                }
            }
            return nil
        }
        |> distinctUntilChanged
        |> deliverOn(self.queue)).start(next: { [weak self] entry in
            guard let strongSelf = self else {
                return
            }
            strongSelf.setCurrentHole(entry: entry)
        })
        
        
    }
    
    deinit {
        self.initialStateDisposable?.dispose()
        self.holesDisposable?.dispose()
        self.readDisposable.dispose()
        self.updateInitialStateDisposable?.dispose()
    }
    
    func setCurrentHole(entry: MessageHistoryHolesViewEntry?) {
        if self.currentHole?.0 != entry {
            self.currentHole?.1.dispose()
            if let entry = entry {
                self.currentHole = (entry, self.fetchHole(entry: entry).start(next: { [weak self] updatedState in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.currentHole = nil
                    strongSelf.stateValue = updatedState
                }))
            } else {
                self.currentHole = nil
            }
        }
    }
    
    private func fetchHole(entry: MessageHistoryHolesViewEntry) -> Signal<State, NoError> {
        
        return .complete()









































































































    }
    
    func applyMaxReadIndex(messageIndex: MessageIndex) {
    }
}

public class FeedHistoryContext {
    fileprivate final class GuardReference {
        private let deallocated: () -> Void
        
        init(deallocated: @escaping () -> Void) {
            self.deallocated = deallocated
        }
        
        deinit {
            self.deallocated()
        }
    }
    
    private let queue = Queue()
    private let impl: QueueLocalObject<FeedHistoryContextImpl>
    
    private let userId: Int64 = Int64.random(in: 0 ..< Int64.max)
    
    public var state: Signal<MessageHistoryViewExternalInput, NoError> {
        let userId = self.userId
        
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            self.impl.with { impl in
                let stateDisposable = impl.state.get().start(next: { state in
                    subscriber.putNext(MessageHistoryViewExternalInput(
                        content: .messages(indices: state.messageIndices, holes: state.holeIndices, userId: userId),
                        maxReadIncomingMessageId: nil,
                        maxReadOutgoingMessageId: nil
                    ))
                })
                disposable.set(stateDisposable)
            }
            
            return disposable
        }
    }
    
    public var maxReadOutgoingMessageId: Signal<MessageId?, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            self.impl.with { impl in
                disposable.set(impl.maxReadOutgoingMessageId.get().start(next: { value in
                    subscriber.putNext(value)
                }))
            }
            
            return disposable
        }
    }

    public var unreadCount: Signal<Int, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()

            self.impl.with { impl in
                disposable.set(impl.unreadCount.get().start(next: { value in
                    subscriber.putNext(value)
                }))
            }

            return disposable
        }
    }
    
    public init(account: Account, feedId: Int32) {
        let queue = self.queue
        let userId = self.userId
        self.impl = QueueLocalObject(queue: queue, generate: {
            return FeedHistoryContextImpl(queue: queue, account: account, feedId: feedId, userId: userId)
        })
    }
    
    public func applyMaxReadIndex(messageIndex: MessageIndex) {
        self.impl.with { impl in
            impl.applyMaxReadIndex(messageIndex: messageIndex)
        }
    }
}
