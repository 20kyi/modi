import Foundation

struct CreateRecordPresignedURLsRequest: Encodable {
    let recordDate: String
    let contentType: String
}

struct PresignedImageURL: Decodable {
    let uploadUrl: String
    let key: String
}

struct RecordPresignedURLsResponse: Decodable {
    let original: PresignedImageURL
    let edited: PresignedImageURL
    let expiresIn: Int
}

struct UploadAPIService: Sendable {
    static let shared = UploadAPIService()

    private let client: APIClient
    private let session: URLSession

    init(client: APIClient = .shared, session: URLSession = .shared) {
        self.client = client
        self.session = session
    }

    func createRecordPresignedURLs(
        recordDate: String,
        contentType: String = "image/jpeg",
        accessToken: String
    ) async throws -> RecordPresignedURLsResponse {
        try await client.request(
            "upload/records/presigned-urls",
            method: "POST",
            body: CreateRecordPresignedURLsRequest(
                recordDate: recordDate,
                contentType: contentType
            ),
            accessToken: accessToken
        )
    }

    func uploadImage(
        data: Data,
        to uploadURLString: String,
        contentType: String = "image/jpeg"
    ) async throws {
        guard let url = URL(string: uploadURLString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.from(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw APIError.server(
                statusCode: httpResponse.statusCode,
                message: "이미지 업로드에 실패했어요. (\(httpResponse.statusCode))"
            )
        }
    }
}
