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

import Collections
import Foundation
import ImmutableData
import QuakesData
import Testing

extension Quake {
  fileprivate var dictionary : Dictionary<String, Any> {
    [
      "properties" : [
        "mag" : self.magnitude,
        "place" : self.name,
        "time" : self.time.timeIntervalSince1970 * 1000.0,
        "updated" : self.time.timeIntervalSince1970 * 1000.0,
      ],
      "geometry" : [
        "coordinates" : [
          self.longitude,
          self.latitude,
        ],
      ],
      "id" : self.quakeId,
    ]
  }
}

final fileprivate class Error : Swift.Error {
  
}

final fileprivate class NetworkSessionTestDouble : @unchecked Sendable {
  var request: URLRequest?
  var decoder: JSONDecoder?
  let data: Data?
  let error = Error()
  
  init(data: Data? = nil) {
    self.data = data
  }
}

extension NetworkSessionTestDouble : RemoteStoreNetworkSession {
  func json<T>(
    for request: URLRequest,
    from decoder: JSONDecoder
  ) async throws -> T where T : Decodable {
    self.request = request
    self.decoder = decoder
    guard
      let data = self.data
    else {
      throw self.error
    }
    let response = try decoder.decode(RemoteResponse.self, from: data)
    return response as! T
  }
}

@Suite final actor RemoteStoreTests {
  private static let state = QuakesState(
    quakes: QuakesState.Quakes(
      data: TreeDictionary(
        Quake(
          quakeId: "1",
          magnitude: 0.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "2",
          magnitude: 1.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "3",
          magnitude: 2.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "4",
          magnitude: 3.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "5",
          magnitude: 4.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "6",
          magnitude: 5.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "7",
          magnitude: 6.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "8",
          magnitude: 7.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        )
      )
    )
  )
}

extension RemoteStoreTests {
  private static var data : Data {
    let features = Self.state.quakes.data.values.map { $0.dictionary }
    let dictionary : Dictionary<String, Any> = [
      "features" : features
    ]
    let data = try! JSONSerialization.data(withJSONObject: dictionary)
    return data
  }
}

extension RemoteStoreTests {
  @Test(
    arguments: [
      (
        QuakesAction.UI.QuakeList.RefreshQuakesRange.allHour,
        "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
      ),
      (
        QuakesAction.UI.QuakeList.RefreshQuakesRange.allDay,
        "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
      ),
      (
        QuakesAction.UI.QuakeList.RefreshQuakesRange.allWeek,
        "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.geojson"
      ),
      (
        QuakesAction.UI.QuakeList.RefreshQuakesRange.allMonth,
        "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson"
      ),
    ]
  ) func fetchRemoteQuakesQueryNoThrow(
    range: QuakesAction.UI.QuakeList.RefreshQuakesRange,
    string: String
  ) async throws {
    let session = NetworkSessionTestDouble(data: Self.data)
    let store = RemoteStore(session: session)
    let quakes = try await store.fetchRemoteQuakesQuery(range: range)
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: string))
    #expect(networkRequest.httpMethod == "GET")
    
    #expect(TreeDictionary(quakes) == Self.state.quakes.data)
  }
}
