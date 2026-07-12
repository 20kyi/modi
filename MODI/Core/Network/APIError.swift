import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case network(String)
    case unauthorized
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "요청 주소가 올바르지 않아요."
        case .invalidResponse:
            "서버 응답을 확인할 수 없어요."
        case .network(let message):
            message
        case .unauthorized:
            "로그인이 필요해요."
        case .server(_, let message):
            message
        }
    }

    static func from(urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet:
            .network("인터넷 연결을 확인해주세요.")
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            .network("서버에 연결할 수 없어요. 백엔드가 실행 중인지, Mac과 iPhone이 같은 Wi-Fi인지 확인해주세요.")
        case .timedOut:
            .network("서버 응답이 없어요. 백엔드 실행 상태를 확인해주세요.")
        case .secureConnectionFailed,
             .serverCertificateUntrusted,
             .clientCertificateRejected,
             .clientCertificateRequired:
            .network("이미지 업로드 연결에 실패했어요. 네트워크를 확인하고 다시 시도해주세요.")
        default:
            .network(urlError.localizedDescription)
        }
    }
}
