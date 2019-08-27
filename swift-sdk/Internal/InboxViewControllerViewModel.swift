//
//
//  Created by Tapash Majumder on 6/12/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

protocol InboxViewControllerViewModelDelegate: class {
    // All these methods should be called on the main thread
    func onViewModelChanged(diff: [SectionedDiffStep<Int, InboxMessageViewModel>])
    func onImageLoaded(forRow row: Int)
}

protocol InboxViewControllerViewModelProtocol {
    var delegate: InboxViewControllerViewModelDelegate? { get set }
    var numMessages: Int { get }
    var unreadCount: Int { get }
    func message(atRow row: Int) -> InboxMessageViewModel
    func remove(atRow row: Int)
    func set(read: Bool, forMessage message: InboxMessageViewModel)
    func createInboxMessageViewController(for message: InboxMessageViewModel, withInboxMode inboxMode: IterableInboxViewController.InboxMode) -> UIViewController?
    func refresh() -> Future<Bool, Error> // Talks to the server and refreshes
    // this works hand in hand with listener.onViewModelChanged.
    // Internal model can't be changed until the view begins update.
    func beganUpdates()
    func endedUpdates()
    func viewWillAppear()
    func viewWillDisappear()
}

class InboxViewControllerViewModel: InboxViewControllerViewModelProtocol {
    weak var delegate: InboxViewControllerViewModelDelegate?
    
    init() {
        ITBInfo()
        if let _ = IterableAPI.internalImplementation {
            messages = IterableAPI.inAppManager.getInboxMessages().map { InboxMessageViewModel(message: $0) }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(onInboxChanged(notification:)), name: .iterableInboxChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        ITBInfo()
        NotificationCenter.default.removeObserver(self)
    }
    
    var numMessages: Int {
        return messages.count
    }
    
    var unreadCount: Int {
        return messages.filter { $0.read == false }.count
    }
    
    func message(atRow row: Int) -> InboxMessageViewModel {
        let message = messages[row]
        loadImageIfNecessary(message)
        return message
    }
    
    func remove(atRow row: Int) {
        IterableAPI.inAppManager.remove(message: messages[row].iterableMessage, location: .inbox, source: .inboxSwipeLeft)
    }
    
    func set(read _: Bool, forMessage message: InboxMessageViewModel) {
        IterableAPI.inAppManager.set(read: true, forMessage: message.iterableMessage)
    }
    
    func refresh() -> Future<Bool, Error> {
        guard let inAppManager = IterableAPI.inAppManager as? InAppManager else {
            return Promise(error: IterableError.general(description: "Did not find inAppManager"))
        }
        
        return inAppManager.scheduleSync()
    }
    
    func createInboxMessageViewController(for message: InboxMessageViewModel, withInboxMode inboxMode: IterableInboxViewController.InboxMode) -> UIViewController? {
        guard let inappManager = IterableAPI.inAppManager as? IterableInAppManagerProtocolInternal else {
            ITBError("Unexpected inappManager type")
            return nil
        }
        return inappManager.createInboxMessageViewController(for: message.iterableMessage, withInboxMode: inboxMode)
    }
    
    func beganUpdates() {
        messages = newMessages
    }
    
    func endedUpdates() {}
    
    func viewWillAppear() {
        ITBInfo()
        sessionManager.viewWillAppear()
    }
    
    func viewWillDisappear() {
        ITBInfo()
        sessionManager.viewWillDisappear()
    }
    
    private func loadImageIfNecessary(_ message: InboxMessageViewModel) {
        guard let imageUrlString = message.imageUrl, let url = URL(string: imageUrlString) else {
            return
        }
        
        if message.imageData == nil {
            loadImage(forMessageId: message.iterableMessage.messageId, fromUrl: url)
        }
    }
    
    private func loadImage(forMessageId messageId: String, fromUrl url: URL) {
        if let networkSession = IterableAPI.internalImplementation?.networkSession {
            NetworkHelper.getData(fromUrl: url, usingSession: networkSession).onSuccess { [weak self] in
                self?.setImageData($0, forMessageId: messageId)
            }.onError {
                ITBError($0.localizedDescription)
            }
        }
    }
    
    private func setImageData(_ data: Data, forMessageId messageId: String) {
        guard let row = messages.firstIndex(where: { $0.iterableMessage.messageId == messageId }) else {
            return
        }
        let message = messages[row]
        message.imageData = data
        
        delegate?.onImageLoaded(forRow: row)
    }
    
    @objc private func onInboxChanged(notification _: NSNotification) {
        ITBInfo()
        
        let oldSectionedValues = AbstractDiffCalculator<Int, InboxMessageViewModel>.buildSectionedValues(values: messages, sectionIndex: 0)
        newMessages = IterableAPI.inAppManager.getInboxMessages().map { InboxMessageViewModel(message: $0) }
        let newSectionedValues = AbstractDiffCalculator<Int, InboxMessageViewModel>.buildSectionedValues(values: newMessages, sectionIndex: 0)
        
        let diff = Dwifft.diff(lhs: oldSectionedValues, rhs: newSectionedValues)
        if diff.count > 0 {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onViewModelChanged(diff: diff)
            }
        }
    }
    
    @objc private func onAppWillEnterForeground(notification _: NSNotification) {
        ITBInfo()
        
        if sessionManager.startSessionWhenAppMovesToForeground {
            sessionManager.viewWillAppear()
            sessionManager.startSessionWhenAppMovesToForeground = false
        }
    }
    
    @objc private func onAppDidEnterBackground(notification _: NSNotification) {
        ITBInfo()
        if sessionManager.session.sessionStartTime != nil {
            // if a session is going on trigger session end
            sessionManager.viewWillDisappear()
            sessionManager.startSessionWhenAppMovesToForeground = true
        }
    }
    
    private var messages = [InboxMessageViewModel]()
    private var newMessages = [InboxMessageViewModel]()
    private var sessionManager = SessionManager()
    
    struct SessionManager {
        var session = IterableInboxSession()
        var startSessionWhenAppMovesToForeground = false
        
        mutating func viewWillAppear() {
            ITBInfo()
            guard session.sessionStartTime == nil else {
                ITBError("Session started twice")
                return
            }
            ITBInfo("Session Start")
            session = IterableInboxSession(sessionStartTime: Date(),
                                           sessionEndTime: nil,
                                           startTotalMessageCount: IterableAPI.inAppManager.getInboxMessages().count,
                                           startUnreadMessageCount: IterableAPI.inAppManager.getUnreadInboxMessagesCount())
        }
        
        mutating func viewWillDisappear() {
            guard let sessionStartTime = session.sessionStartTime else {
                ITBError("Session ended without start")
                return
            }
            ITBInfo("Session End")
            let sessionToTrack = IterableInboxSession(sessionStartTime: sessionStartTime,
                                                      sessionEndTime: Date(),
                                                      startTotalMessageCount: session.startTotalMessageCount,
                                                      startUnreadMessageCount: session.startUnreadMessageCount,
                                                      endTotalMessageCount: IterableAPI.inAppManager.getInboxMessages().count,
                                                      endUnreadMessageCount: IterableAPI.inAppManager.getUnreadInboxMessagesCount())
            IterableAPI.track(inboxSession: sessionToTrack)
            session = IterableInboxSession()
        }
    }
}
