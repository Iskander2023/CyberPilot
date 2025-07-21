//
//  APIService.swift
//  CyberPilot
//
//  Created by Admin on 21/07/25.
//
import Foundation


class APIService {
    static let shared = APIService()
    private init() {}
    
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)

    private let baseURL = AppConfig.Addresses.robotsList

    func fetchRobots(token: String, completion: @escaping (Result<[Robot], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let decoder = JSONDecoder()
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        decoder.dateDecodingStrategy = .formatted(formatter)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            if httpResponse.statusCode == 404 {
                self.logger.info("У вас нет назначенных роботов.")
                completion(.success([]))
                return
            }

            guard httpResponse.statusCode == 200,
                  let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }

            do {
                let robots = try decoder.decode([Robot].self, from: data)
                completion(.success(robots))
            } catch {
                completion(.failure(error))
            }

        }.resume()
    }

}
