//
//  ChatMessageRow.swift
//  CyberPilot
//
//  Created by Admin on 23/07/25.
//

import SwiftUI


struct ChatMessageRow: View {
    let message: ChatMessage
    let userName: String

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                // ВЕРХНЯЯ СТРОКА: имя + иконка + время
                HStack(spacing: 8) {
                    if message.sender == .user {
                        // Время слева
                        Text(formatTime(message.time))
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        // Имя и иконка пользователя справа
                        Text(userName)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Image(systemName: "person")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.blue)
                    } else {
                        // Иконка и имя робота слева
                        Image(systemName: "brain.head.profile")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.green)

                        Text("Робот")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        // Время справа
                        Text(formatTime(message.time))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)

                // СООБЩЕНИЕ
                Text(message.text)
                    .frame(maxWidth: 250, alignment: message.sender == .user ? .trailing : .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.sender == .user ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, alignment: message.sender == .user ? .trailing : .leading)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            if message.sender == .robot {
                Spacer()
            }
        }
        .id(message.id)
    }


    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
