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

import CowBox
import Foundation

@CowBox(init: .withPackage) public struct Quake: Hashable, Sendable {
  public let quakeId: String
  public let magnitude: Double
  public let time: Date
  public let updated: Date
  public let name: String
  public let longitude: Double
  public let latitude: Double
}

extension Quake: Identifiable {
  public var id: String {
    self.quakeId
  }
}

extension Quake {
  public static var xxsmall: Self {
    Self(
      quakeId: "xxsmall",
      magnitude: 0.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
  public static var xsmall: Self {
    Self(
      quakeId: "xsmall",
      magnitude: 1.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
  public static var small: Self {
    Self(
      quakeId: "small",
      magnitude: 2.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
  public static var medium: Self {
    Self(
      quakeId: "medium",
      magnitude: 3.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
  public static var large: Self {
    Self(
      quakeId: "large",
      magnitude: 4.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
  public static var xlarge: Self {
    Self(
      quakeId: "xlarge",
      magnitude: 5.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
  public static var xxlarge: Self {
    Self(
      quakeId: "xxlarge",
      magnitude: 6.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
  public static var xxxlarge: Self {
    Self(
      quakeId: "xxxlarge",
      magnitude: 7.5,
      time: .now,
      updated: .now,
      name: "West of California",
      longitude: -125,
      latitude: 35
    )
  }
}
