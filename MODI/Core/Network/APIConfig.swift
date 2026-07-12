import Foundation

enum APIConfig {
    /// Railway 배포 서버 (DEBUG 테스트용)
    private static let stagingBaseURL = "https://modi-production-281f.up.railway.app/api"

    /// Mac 로컬 IP (실기기 로컬 테스트용). Wi-Fi가 바뀌면 `ipconfig getifaddr en0`
    private static let macLocalHost = "192.168.0.143"

    #if DEBUG
    static var baseURL: URL {
        URL(string: stagingBaseURL)!
        // 로컬 백엔드 (`npm run start:dev`) 테스트 시:
        // #if targetEnvironment(simulator)
        // URL(string: "http://127.0.0.1:3000/api")!
        // #else
        // URL(string: "http://\(macLocalHost):3000/api")!
        // #endif
    }
    #else
    static let baseURL = URL(string: "https://api.modi.app/api")!
    #endif
}
