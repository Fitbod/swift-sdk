//
//
//  Created by Tapash Majumder on 1/8/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

// Adhering to Codable
extension UIEdgeInsets : Codable {
    enum CodingKeys: String, CodingKey {
        case top
        case left
        case bottom
        case right
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let top = try container.decode(Double.self, forKey: .top)
        let left = try container.decode(Double.self, forKey: .left)
        let bottom = try container.decode(Double.self, forKey: .bottom)
        let right = try container.decode(Double.self, forKey: .right)
        
        self.init(top: CGFloat(top), left: CGFloat(left), bottom: CGFloat(bottom), right: CGFloat(right))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Double(top), forKey: .top)
        try container.encode(Double(left), forKey: .left)
        try container.encode(Double(bottom), forKey: .bottom)
        try container.encode(Double(right), forKey: .right)
    }
}

extension IterableInAppMessage : Codable {
    enum CodingKeys: String, CodingKey {
        case messageId
        case campaignId
        case channelName
        case contentType
        case content
        case extraInfo
        case processed
        case consumed
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(messageId: "",
                      campaignId: "",
                      content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
                      )
            return
        }
        
        guard let contentType = (try? container.decode(IterableInAppContentType.self, forKey: .contentType)), contentType == .html else {
            // unexpected content type
            ITBError("Unexpected contentType, returning default")
            self.init(messageId: "",
                      campaignId: "",
                      content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
            )
            return
        }
        
        let messageId = (try? container.decode(String.self, forKey: .messageId)) ?? ""
        let campaignId = (try? container.decode(String.self, forKey: .campaignId)) ?? ""
        let channelName = (try? container.decode(String.self, forKey: .channelName)) ?? ""
        let content = (try? container.decode(IterableHtmlInAppContent.self, forKey: .content)) ?? IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
        let extraInfo = (try? container.decode([String : String].self, forKey: .extraInfo)) ?? nil
        
        self.init(messageId: messageId,
                  campaignId: campaignId,
                  channelName: channelName,
                  contentType: contentType,
                  content: content,
                  extraInfo: extraInfo)
        
        self.processed = (try? container.decode(Bool.self, forKey: .processed)) ?? false
        self.consumed = (try? container.decode(Bool.self, forKey: .consumed)) ?? false
    }
    
    public func encode(to encoder: Encoder) {
        guard let content = content as? IterableHtmlInAppContent else {
            return
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(messageId, forKey: .messageId)
        try? container.encode(campaignId, forKey: .campaignId)
        try? container.encode(channelName, forKey: .channelName)
        try? container.encode(contentType, forKey: .contentType)
        try? container.encode(content, forKey: .content)
        try? container.encode(extraInfo, forKey: .extraInfo)
        try? container.encode(processed, forKey: .processed)
        try? container.encode(consumed, forKey: .consumed)
    }
}

protocol InAppPersistenceProtocol {
    associatedtype Sequence : Swift.Sequence where Sequence.Element == IterableInAppMessage
    var messages : Sequence { get }
    func persist(_ messages: Sequence)
}


class MemoryPersister : InAppPersistenceProtocol {
    var messages = [IterableInAppMessage]()

    func persist(_ messages: [IterableInAppMessage]) {
        self.messages = messages
    }
}
