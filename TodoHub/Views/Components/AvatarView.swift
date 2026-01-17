//
//  AvatarView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct AvatarView: View {
    let login: String?
    var size: CGFloat = 32
    
    var body: some View {
        AsyncImage(url: avatarURL) { phase in
            switch phase {
            case .empty:
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.8))
                    .foregroundStyle(.secondary)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.8))
                    .foregroundStyle(.secondary)
            @unknown default:
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.8))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var avatarURL: URL? {
        guard let login = login else { return nil }
        return URL(string: "https://github.com/\(login).png?size=\(Int(size * 2))")
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(login: "octocat")
        AvatarView(login: "octocat", size: 64)
        AvatarView(login: nil)
    }
}
