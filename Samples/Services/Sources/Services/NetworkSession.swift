//
//  Copyright 2024 Rick van Voorden and Bill Fisher
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public protocol NetworkSessionURLSession: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSessionURLSession {
  
}

package protocol NetworkSessionJSONHandler {
  static func handle<T>(
    _ data: Data,
    with response: URLResponse,
    dataHandler: (some NetworkJSONHandlerDataHandler).Type,
    from decoder: some NetworkJSONHandlerDecoder
  ) throws -> T where T : Decodable
}

extension NetworkJSONHandler: NetworkSessionJSONHandler {
  
}

final public class NetworkSession<URLSession>: Sendable where URLSession : NetworkSessionURLSession {
  private let urlSession: URLSession
  
  public init(urlSession: URLSession) {
    self.urlSession = urlSession
  }
}

extension NetworkSession {
  public func json<T>(
    for request: URLRequest,
    from decoder: JSONDecoder
  ) async throws -> T where T : Decodable {
    try await self.json(
      for: request,
      jsonHandler: NetworkJSONHandler.self,
      dataHandler: NetworkDataHandler.self,
      from: decoder
    )
  }
}

extension NetworkSession {
  package func json<T>(
    for request: URLRequest,
    jsonHandler: (some NetworkSessionJSONHandler).Type,
    dataHandler: (some NetworkJSONHandlerDataHandler).Type,
    from decoder: some NetworkJSONHandlerDecoder
  ) async throws -> T where T : Decodable {
    let (data, response) = try await {
      do {
        return try await self.urlSession.data(for: request)
      } catch {
        throw Error(
          code: .sessionError,
          underlying: error
        )
      }
    }()
    
    do {
      return try jsonHandler.handle(
        data,
        with: response,
        dataHandler: dataHandler,
        from: decoder
      )
    } catch {
      throw Error(
        code: .jsonHandlerError,
        underlying: error
      )
    }
  }
}

extension NetworkSession {
  package struct Error : Swift.Error {
    package enum Code: Equatable {
      case sessionError
      case jsonHandlerError
    }
    
    package let code: Code
    package let underlying: Swift.Error?
  }
}
