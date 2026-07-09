import Foundation

enum APIConfig {
    /// Mac 로컬 IP (실기기 테스트용). Wi-Fi가 바뀌면 터미널에서 `ipconfig getifaddr en0`로 확인 후 수정하세요.
    private static let macLocalHost = "192.168.0.143" // 192.168.0.143

    /// 로컬 백엔드 (`npm run start:dev`)
    #if DEBUG
    static var baseURL: URL {
        #if targetEnvironment(simulator)
        // 시뮬레이터 → Mac localhost
        URL(string: "http://127.0.0.1:3000/api")!
        #else
        // 실기기 → 같은 Wi-Fi에 있는 Mac IP
        URL(string: "http://\(macLocalHost):3000/api")!
        #endif
    }
    #else
    static let baseURL = URL(string: "https://api.modi.app/api")!
    #endif
}
