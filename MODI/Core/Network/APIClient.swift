import Foundation

struct APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func request<Response: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        accessToken: String? = nil
    ) async throws -> Response {
        guard let url = Self.makeURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.from(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw mapError(statusCode: httpResponse.statusCode, data: data)
        }

        return try decoder.decode(Response.self, from: data)
    }

    func requestVoid(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        accessToken: String? = nil
    ) async throws {
        guard let url = Self.makeURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.from(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw mapError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private static func makeURL(path: String) -> URL? {
        let base = APIConfig.baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/\(endpoint)")
    }

    private func mapError(statusCode: Int, data: Data) -> APIError {
        if statusCode == 401 {
            return .unauthorized
        }

        if let payload = try? decoder.decode(APIErrorResponse.self, from: data) {
            return .server(statusCode: statusCode, message: payload.resolvedMessage)
        }

        return .server(statusCode: statusCode, message: "서버 오류가 발생했어요. (\(statusCode))")
    }
}

private struct APIErrorResponse: Decodable {
    let message: MessageValue?
    let statusCode: Int?

    enum MessageValue: Decodable {
        case string(String)
        case array([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(String.self) {
                self = .string(value)
                return
            }
            if let value = try? container.decode([String].self) {
                self = .array(value)
                return
            }
            self = .string("요청을 처리하지 못했어요.")
        }
    }

    var resolvedMessage: String {
        switch message {
        case .string(let value):
            value
        case .array(let values):
            values.joined(separator: "\n")
        case .none:
            "요청을 처리하지 못했어요."
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeClosure = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
