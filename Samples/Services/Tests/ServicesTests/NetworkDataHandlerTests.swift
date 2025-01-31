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

import Services
import Testing

@Suite final actor NetworkDataHandlerTestCase {
  
}

extension NetworkDataHandlerTestCase {
  static var throwsStatusCodeErrorArguments: Array<Int> {
    Array(100...199) + Array(300...599)
  }
}

extension NetworkDataHandlerTestCase {
  static var noThrowArguments: Array<Int> {
    Array(200...299)
  }
}

extension NetworkDataHandlerTestCase {
  @Test func throwsResponseError() throws {
    #expect {
      try NetworkDataHandler.handle(
        DataTestDouble(),
        with: URLResponseTestDouble()
      )
    } throws: { error in
      let error = try #require(error as? NetworkDataHandler.Error)
      return error.code == .responseError
    }
  }
}

extension NetworkDataHandlerTestCase {
  @Test(arguments: Self.throwsStatusCodeErrorArguments) func throwsStatusCodeError(statusCode: Int) throws {
    #expect {
      try NetworkDataHandler.handle(
        DataTestDouble(),
        with: HTTPURLResponseTestDouble(statusCode: statusCode)
      )
    } throws: { error in
      let error = try #require(error as? NetworkDataHandler.Error)
      return error.code == .statusCodeError
    }
  }
}

extension NetworkDataHandlerTestCase {
  @Test(arguments: Self.noThrowArguments) func noThrow(statusCode: Int) throws {
    let data = try NetworkDataHandler.handle(
      DataTestDouble(),
      with: HTTPURLResponseTestDouble(statusCode: statusCode)
    )
    
    #expect(data == DataTestDouble())
  }
}
