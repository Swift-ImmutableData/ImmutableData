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
import Services
import Testing

//  https://github.com/swiftlang/swift/issues/74882

final fileprivate class Error : Swift.Error {
  
}

final fileprivate class NetworkSessionURLSessionTestDouble: @unchecked Sendable, NetworkSessionURLSession {
  var parameterRequest: URLRequest?
  var returnData: Data?
  var returnResponse: URLResponse?
  var returnError = Error()
}

extension NetworkSessionURLSessionTestDouble {
  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    self.parameterRequest = request
    guard
      let data = self.returnData,
      let response = self.returnResponse
    else {
      throw self.returnError
    }
    return (data, response)
  }
}

final fileprivate class JSONTestDouble: @unchecked Sendable, Decodable {
  
}

final fileprivate class NetworkSessionJSONHandlerTestDouble: @unchecked Sendable, NetworkSessionJSONHandler {
  static nonisolated(unsafe) var parameterData: Data?
  static nonisolated(unsafe) var parameterResponse: URLResponse?
  static nonisolated(unsafe) var returnJSON: JSONTestDouble?
  static let returnError = Error()
}

extension NetworkSessionJSONHandlerTestDouble {
  static func handle<DataHandler, JSONDecoder, T>(
    _ data: Data,
    with response: URLResponse,
    dataHandler: DataHandler.Type,
    from decoder: JSONDecoder
  ) throws -> T where DataHandler : NetworkJSONHandlerDataHandler, JSONDecoder : NetworkJSONHandlerDecoder, T : Decodable {
    self.parameterData = data
    self.parameterResponse = response
    guard
      let json = self.returnJSON
    else {
      throw self.returnError
    }
    return json as! T
  }
}

@Suite(.serialized) final actor NetworkSessionTestCase {
  private let urlSession = NetworkSessionURLSessionTestDouble()
  
  init() {
    NetworkSessionJSONHandlerTestDouble.parameterData = nil
    NetworkSessionJSONHandlerTestDouble.parameterResponse = nil
    NetworkSessionJSONHandlerTestDouble.returnJSON = nil
  }
}

extension NetworkSessionTestCase {
  @Test func throwsSessionError() async throws {
    do {
      let session = NetworkSession(urlSession: self.urlSession)
      let _ = try await session.json(
        for: URLRequestTestDouble(),
        jsonHandler: NetworkSessionJSONHandlerTestDouble.self,
        dataHandler: NetworkDataHandler.self,
        from: JSONDecoder()
      ) as JSONTestDouble
      #expect(false)
    } catch {
      #expect(self.urlSession.parameterRequest == URLRequestTestDouble())
      
      #expect(NetworkSessionJSONHandlerTestDouble.parameterData == nil)
      #expect(NetworkSessionJSONHandlerTestDouble.parameterResponse == nil)
      
      let error = try #require(error as? NetworkSession<NetworkSessionURLSessionTestDouble>.Error)
      let underlying = try #require(error.underlying as? Error)
      #expect(error.code == .sessionError)
      #expect(underlying === self.urlSession.returnError)
    }
  }
}

extension NetworkSessionTestCase {
  @Test func throwsJSONHandlerError() async throws {
    do {
      self.urlSession.returnData = DataTestDouble()
      self.urlSession.returnResponse = URLResponseTestDouble()
      
      let session = NetworkSession(urlSession: self.urlSession)
      let _ = try await session.json(
        for: URLRequestTestDouble(),
        jsonHandler: NetworkSessionJSONHandlerTestDouble.self,
        dataHandler: NetworkDataHandler.self,
        from: JSONDecoder()
      ) as JSONTestDouble
      #expect(false)
    } catch {
      #expect(self.urlSession.parameterRequest == URLRequestTestDouble())
      
      #expect(NetworkSessionJSONHandlerTestDouble.parameterData == self.urlSession.returnData)
      #expect(NetworkSessionJSONHandlerTestDouble.parameterResponse === self.urlSession.returnResponse)
      
      let error = try #require(error as? NetworkSession<NetworkSessionURLSessionTestDouble>.Error)
      let underlying = try #require(error.underlying as? Error)
      #expect(error.code == .jsonHandlerError)
      #expect(underlying === NetworkSessionJSONHandlerTestDouble.returnError)
    }  }
}

extension NetworkSessionTestCase {
  @Test func noThrow() async throws {
    self.urlSession.returnData = DataTestDouble()
    self.urlSession.returnResponse = URLResponseTestDouble()
    
    NetworkSessionJSONHandlerTestDouble.returnJSON = JSONTestDouble()
    
    let session = NetworkSession(urlSession: self.urlSession)
    let json = try await session.json(
      for: URLRequestTestDouble(),
      jsonHandler: NetworkSessionJSONHandlerTestDouble.self,
      dataHandler: NetworkDataHandler.self,
      from: JSONDecoder()
    ) as JSONTestDouble
    
    #expect(self.urlSession.parameterRequest == URLRequestTestDouble())
    
    #expect(NetworkSessionJSONHandlerTestDouble.parameterData == self.urlSession.returnData)
    #expect(NetworkSessionJSONHandlerTestDouble.parameterResponse === self.urlSession.returnResponse)
    
    #expect(json === NetworkSessionJSONHandlerTestDouble.returnJSON)
  }
}
