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

package protocol NetworkJSONHandlerDataHandler {
  static func handle(
    _ data: Data,
    with response: URLResponse
  ) throws -> Data
}

extension NetworkDataHandler: NetworkJSONHandlerDataHandler {
  
}

package protocol NetworkJSONHandlerDecoder {
  func decode<T>(
    _ type: T.Type,
    from data: Data
  ) throws -> T where T : Decodable
}

extension JSONDecoder: NetworkJSONHandlerDecoder {
  
}

package struct NetworkJSONHandler {
  package static func handle<T>(
    _ data: Data,
    with response: URLResponse,
    dataHandler: (some NetworkJSONHandlerDataHandler).Type,
    from decoder: some NetworkJSONHandlerDecoder
  ) throws -> T where T : Decodable {
    guard
      let mimeType = response.mimeType?.lowercased(),
      mimeType == "application/json"
    else {
      throw Error(
        code: .mimeTypeError,
        underlying: nil
      )
    }
    
    let data = try {
      do {
        return try dataHandler.handle(
          data,
          with: response
        )
      } catch {
        throw Error(
          code: .dataHandlerError,
          underlying: error
        )
      }
    }()
    
    do {
      return try decoder.decode(
        T.self,
        from: data
      )
    } catch {
      throw Error(
        code: .jsonDecoderError,
        underlying: error
      )
    }
  }
}

extension NetworkJSONHandler {
  package struct Error : Swift.Error {
    package enum Code: Equatable {
      case mimeTypeError
      case dataHandlerError
      case jsonDecoderError
    }
    
    package let code: Code
    package let underlying: Swift.Error?
  }
}
