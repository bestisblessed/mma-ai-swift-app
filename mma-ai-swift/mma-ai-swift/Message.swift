//
//  Message.swift
//  mma-ai-swift
//
//  Created by Tyler on 3/19/25.
//

import Foundation

struct Message: Identifiable, Codable {
    var id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let imageData: Data?
    let isLoading: Bool
    
    init(content: String, isUser: Bool, timestamp: Date, imageData: Data? = nil, isLoading: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.imageData = imageData
        self.isLoading = isLoading
    }
    
    // Add a new initializer that accepts an id parameter
    init(id: String, content: String, isUser: Bool, timestamp: Date, imageData: Data? = nil, isLoading: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.imageData = imageData
        self.isLoading = isLoading
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // Add CodingKeys and required Codable methods for UUID
    enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp, imageData, isLoading
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        isLoading = try container.decodeIfPresent(Bool.self, forKey: .isLoading) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encode(isLoading, forKey: .isLoading)
    }
}
