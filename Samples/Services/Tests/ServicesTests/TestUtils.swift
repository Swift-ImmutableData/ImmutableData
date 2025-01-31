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

func DataTestDouble() -> Data {
  Data(UInt8.min...UInt8.max)
}

func HTTPURLResponseTestDouble(
  statusCode: Int = 200,
  headerFields: Dictionary<String, String>? = nil
) -> HTTPURLResponse {
  HTTPURLResponse(
    url: URLTestDouble(),
    statusCode: statusCode,
    httpVersion: "HTTP/1.1",
    headerFields: headerFields
  )!
}

func URLRequestTestDouble() -> URLRequest {
  URLRequest(url: URLTestDouble())
}

func URLResponseTestDouble() -> URLResponse {
  URLResponse(
    url: URLTestDouble(),
    mimeType: nil,
    expectedContentLength: 0,
    textEncodingName: nil
  )
}

func URLTestDouble() -> URL {
  URL(string: "https://www.swift.org")!
}
