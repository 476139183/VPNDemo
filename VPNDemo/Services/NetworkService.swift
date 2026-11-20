import Foundation
import Alamofire

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .noData: return "无数据返回"
        case .decodingError: return "数据解析失败"
        case .serverError(let code): return "服务器错误: \(code)"
        case .networkError(let error): return error.localizedDescription
        }
    }
}

final class NetworkService {
    static let shared = NetworkService()
    
    private let session: Session
    private let baseURL: String
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        session = Session(configuration: configuration)
        baseURL = "https://api.example.com"
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let url = baseURL + endpoint
        
        session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers
        )
        .validate()
        .responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                if let statusCode = response.response?.statusCode {
                    completion(.failure(.serverError(statusCode)))
                } else {
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }
    
    func request(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        let url = baseURL + endpoint
        
        session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers
        )
        .validate()
        .responseData { response in
            switch response.result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                if let statusCode = response.response?.statusCode {
                    completion(.failure(.serverError(statusCode)))
                } else {
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }
}
