//
//  Message.swift
//  mma-ai-swift
//
//  Created by Tyler on 3/19/25.
//

import Foundation

struct Message: Identifiable {
    let id = UUID()
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
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
