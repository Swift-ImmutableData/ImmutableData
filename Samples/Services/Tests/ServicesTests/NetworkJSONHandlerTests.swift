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

final fileprivate class Error : Swift.Error {
  
}

final fileprivate class DataHandlerTestDouble: NetworkJSONHandlerDataHandler {
  static nonisolated(unsafe) var parameterData: Data?
  static nonisolated(unsafe) var parameterResponse: URLResponse?
  static nonisolated(unsafe) var returnData: Data?
  static let returnError = Error()
}

extension DataHandlerTestDouble {
  static func handle(
    _ data: Data,
    with response: URLResponse
  ) throws -> Data {
    self.parameterData = data
    self.parameterResponse = response
    guard
      let data = self.returnData
    else {
      throw self.returnError
    }
    return data
  }
}

final fileprivate class JSONTestDouble: Decodable {
  
}

final fileprivate class JSONDecoderTestDouble: NetworkJSONHandlerDecoder {
  var parameterType: Any.Type?
  var parameterData: Data?
  var returnJSON: JSONTestDouble?
  let returnError = Error()
}

extension JSONDecoderTestDouble {
  func decode<T>(
    _ type: T.Type,
    from data: Data
  ) throws -> T where T : Decodable {
    self.parameterType = type
    self.parameterData = data
    guard
      let json = self.returnJSON
    else {
      throw self.returnError
    }
    return json as! T
  }
}

@Suite(.serialized) final actor NetworkJSONHandlerTestCase {
  init() {
    DataHandlerTestDouble.parameterData = nil
    DataHandlerTestDouble.parameterResponse = nil
    DataHandlerTestDouble.returnData = nil
  }
}

extension NetworkJSONHandlerTestCase {
  @Test func throwsMimeTypeError() throws {
    let response = HTTPURLResponseTestDouble(headerFields: ["content-type": "image/png"])
    let decoder = JSONDecoderTestDouble()
    
    #expect {
      try NetworkJSONHandler.handle(
        DataTestDouble(),
        with: response,
        dataHandler: DataHandlerTestDouble.self,
        from: decoder
      ) as JSONTestDouble
    } throws: { error in
      #expect(DataHandlerTestDouble.parameterData == nil)
      #expect(DataHandlerTestDouble.parameterResponse == nil)
      
      #expect(decoder.parameterType == nil)
      #expect(decoder.parameterData == nil)
      
      let error = try #require(error as? NetworkJSONHandler.Error)
      return (error.code == .mimeTypeError) && (error.underlying == nil)
    }
  }
}

extension NetworkJSONHandlerTestCase {
  @Test func throwsDataHandlerError() throws {
    let response = HTTPURLResponseTestDouble(headerFields: ["content-type": "application/json"])
    let decoder = JSONDecoderTestDouble()
    
    #expect {
      try NetworkJSONHandler.handle(
        DataTestDouble(),
        with: response,
        dataHandler: DataHandlerTestDouble.self,
        from: decoder
      ) as JSONTestDouble
    } throws: { error in
      #expect(DataHandlerTestDouble.parameterData == DataTestDouble())
      #expect(DataHandlerTestDouble.parameterResponse === response)
      
      #expect(decoder.parameterType == nil)
      #expect(decoder.parameterData == nil)
      
      let error = try #require(error as? NetworkJSONHandler.Error)
      let underlying = try #require(error.underlying as? Error)
      return (error.code == .dataHandlerError) && (underlying === DataHandlerTestDouble.returnError)
    }
  }
}

extension NetworkJSONHandlerTestCase {
  @Test func throwsJSONDecoderError() {
    DataHandlerTestDouble.returnData = DataTestDouble()
    
    let response = HTTPURLResponseTestDouble(headerFields: ["content-type": "application/json"])
    let decoder = JSONDecoderTestDouble()
    
    #expect {
      try NetworkJSONHandler.handle(
        DataTestDouble(),
        with: response,
        dataHandler: DataHandlerTestDouble.self,
        from: decoder
      ) as JSONTestDouble
    } throws: { error in
      #expect(DataHandlerTestDouble.parameterData == DataTestDouble())
      #expect(DataHandlerTestDouble.parameterResponse === response)
      
      #expect(decoder.parameterType == JSONTestDouble.self)
      #expect(decoder.parameterData == DataTestDouble())
      
      let error = try #require(error as? NetworkJSONHandler.Error)
      let underlying = try #require(error.underlying as? Error)
      return (error.code == .jsonDecoderError) && (underlying === decoder.returnError)
    }
  }
}

extension NetworkJSONHandlerTestCase {
  @Test func noThrow() throws {
    DataHandlerTestDouble.returnData = DataTestDouble()
    
    let response = HTTPURLResponseTestDouble(headerFields: ["content-type": "application/json"])
    let decoder = JSONDecoderTestDouble()
    decoder.returnJSON = JSONTestDouble()
    
    let json = try NetworkJSONHandler.handle(
      DataTestDouble(),
      with: response,
      dataHandler: DataHandlerTestDouble.self,
      from: decoder
    ) as JSONTestDouble
    
    #expect(DataHandlerTestDouble.parameterData == DataTestDouble())
    #expect(DataHandlerTestDouble.parameterResponse === response)
    
    #expect(decoder.parameterType == JSONTestDouble.self)
    #expect(decoder.parameterData == DataTestDouble())
    
    #expect(json === decoder.returnJSON)
  }
}
