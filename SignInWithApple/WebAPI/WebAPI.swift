/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

struct WebAPI {
  static let baseURL = "http://127.0.0.1:8080" // e.g. https://foobar.ngrok.io (no trailing slash)

  static var accessToken: String?

  enum WebAPIError: Error {
    case identityTokenMissing
    case unableToDecodeIdentityToken
    case unableToEncodeJSONData
    case unableToDecodeJSONData
    case unauthorized
    case invalidResponse
    case httpError(statusCode: Int)
  }

  struct SIWAAuthRequestBody: Encodable {
    let firstName: String?
    let lastName: String?
    let appleIdentityToken: String
  }

  struct UserResponse: Codable {
    let accessToken: String?
    let user: UserProfile
  }

  static func authorizeUsingSIWA(
    identityToken: Data?,
    email: String?,
    firstName: String?,
    lastName: String?,
    completion: @escaping (Result<UserProfile, Error>) -> Void
  ) {
    // TODO: implement
    // 1
    guard let identityToken = identityToken else {
      completion(.failure(WebAPIError.identityTokenMissing))
      return
    }
    print ("identityToken :", identityToken)
    // 2
    guard let identityTokenString = String(data: identityToken, encoding: .utf8) else {
      completion(.failure(WebAPIError.unableToDecodeIdentityToken))
      return
    }

    // 3
    let body = SIWAAuthRequestBody(
      firstName: firstName,
      lastName: lastName,
      appleIdentityToken: identityTokenString
    )

    // 4
    guard let jsonBody = try? JSONEncoder().encode(body) else {
      completion(.failure(WebAPIError.unableToEncodeJSONData))
      return
    }
    // 1
    let session = URLSession.shared
    let url = URL(string: "\(baseURL)/api/auth/siwa")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // 2
    session.uploadTask(with: request, from: jsonBody) { (data, response, error) in
      // 3
      do {
        let userResponse: UserResponse =
          try parseResponse(response, data: data, error: error)
        // 4
        accessToken = userResponse.accessToken
        print("accessToken :", accessToken ?? "default value")

        // 5
        completion(.success(userResponse.user))
      } catch {
        completion(.failure(error))
      }
    }.resume()


//    completion(.failure(WebAPIError.httpError(statusCode: 418)))
  }

  static func getProfile(
    completion: @escaping (Result<UserProfile, Error>) -> Void
  ) {
    guard let accessToken = Self.accessToken else {
      completion(.failure(WebAPIError.unauthorized))
      return
    }

    let session = URLSession.shared
    let url = URL(string: "\(baseURL)/api/users/me")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    session.dataTask(with: request) { data, response, error in
      do {
        let userResponse: UserResponse = try parseResponse(response, data: data, error: error)
        completion(.success(userResponse.user))
      } catch {
        completion(.failure(error))
      }
    }.resume()
  }
}

extension WebAPI {
  static func parseResponse<T: Decodable>(_ response: URLResponse?, data: Data?, error: Error?) throws -> T {
    if let error = error {
      throw error
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw WebAPIError.invalidResponse
    }

    if !(200...299).contains(httpResponse.statusCode) {
      throw WebAPIError.httpError(statusCode: httpResponse.statusCode)
    }

    guard let data = data, let decoded = try? JSONDecoder().decode(T.self, from: data) else {
      throw WebAPIError.unableToDecodeJSONData
    }
    return decoded
  }
}
