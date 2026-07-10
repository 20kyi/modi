import Foundation

extension Data {
    static func fromDataURLString(_ value: String) -> Data? {
        if let commaIndex = value.firstIndex(of: ",") {
            let payload = String(value[value.index(after: commaIndex)...])
            return Data(base64Encoded: payload)
        }
        return Data(base64Encoded: value)
    }

    /// Presigned GET URL, 공개 S3 URL, data URL 문자열에서 이미지 데이터를 로드합니다.
    static func fromImageReference(_ value: String) async -> Data? {
        if value.hasPrefix("data:") {
            return fromDataURLString(value)
        }

        guard let url = URL(string: value) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }
}

enum RemoteImageLoader {
    static func load(from urlString: String) async -> Data? {
        await Data.fromImageReference(urlString)
    }
}
