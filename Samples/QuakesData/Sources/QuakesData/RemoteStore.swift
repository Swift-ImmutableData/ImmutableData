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

//  https://developer.apple.com/forums/thread/770288

package struct RemoteResponse: Hashable, Codable, Sendable {
  private let features: Array<Feature>
}

extension RemoteResponse {
  fileprivate struct Feature: Hashable, Codable, Sendable {
    let properties: Properties
    let geometry: Geometry
    let id: String
  }
}

extension RemoteResponse.Feature {
  struct Properties: Hashable, Codable, Sendable {
    //  Earthquakes from USGS can have null magnitudes.
    //  ¯\_(ツ)_/¯
    let mag: Double?
    let place: String
    let time: Date
    let updated: Date
  }
}

extension RemoteResponse.Feature {
  struct Geometry: Hashable, Codable, Sendable {
    let coordinates: Array<Double>
  }
}

extension RemoteResponse.Feature {
  var quake: Quake {
    Quake(
      quakeId: self.id,
      magnitude: self.properties.mag ?? 0.0,
      time: self.properties.time,
      updated: self.properties.updated,
      name: self.properties.place,
      longitude: self.geometry.coordinates[0],
      latitude: self.geometry.coordinates[1]
    )
  }
}

extension RemoteResponse {
  fileprivate func quakes() -> Array<Quake> {
    self.features.map { $0.quake }
  }
}

public protocol RemoteStoreNetworkSession: Sendable {
  func json<T>(
    for request: URLRequest,
    from decoder: JSONDecoder
  ) async throws -> T where T : Decodable
}

final public actor RemoteStore<NetworkSession>: PersistentSessionRemoteStore where NetworkSession : RemoteStoreNetworkSession {
  private let session: NetworkSession
  
  public init(session: NetworkSession) {
    self.session = session
  }
}

extension RemoteStore {
  private static func url(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) -> URL? {
    switch range {
    case .allHour:
      return URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson")
    case .allDay:
      return URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson")
    case .allWeek:
      return URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.geojson")
    case .allMonth:
      return URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson")
    }
  }
}

extension RemoteStore {
  package struct Error : Swift.Error {
    package enum Code: Equatable {
      case urlError
    }
    
    package let code: Self.Code
  }
}

extension RemoteStore {
  private static func networkRequest(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) throws -> URLRequest {
    guard
      let url = Self.url(range: range)
    else {
      throw Error(code: .urlError)
    }
    return URLRequest(url: url)
  }
}

extension RemoteStore {
  public func fetchRemoteQuakesQuery(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) async throws -> Array<Quake> {
    let networkRequest = try Self.networkRequest(range: range)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    let response: RemoteResponse = try await self.session.json(
      for: networkRequest,
      from: decoder
    )
    return response.quakes()
  }
}
