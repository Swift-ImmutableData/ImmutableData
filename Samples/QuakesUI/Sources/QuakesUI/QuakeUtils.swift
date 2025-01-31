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

import CoreLocation
import MapKit
import QuakesData
import SwiftUI

extension Quake {
  static var previewQuakes: Array<Self> {
    [
      .xxsmall,
      .xsmall,
      .small,
      .medium,
      .large,
      .xlarge,
      .xxlarge,
      .xxxlarge
    ]
  }
}

extension Quake {
  var magnitudeString: String {
    self.magnitude.formatted(.number.precision(.fractionLength(1)))
  }
}

extension Quake {
  var fullDate: String {
    self.time.formatted(date: .complete, time: .complete)
  }
}

extension Quake {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: self.latitude,
      longitude: self.longitude
    )
  }
}

extension Quake {
  var color: Color {
    switch self.magnitude {
    case 0..<1:
      return .green
    case 1..<2:
      return .yellow
    case 2..<3:
      return .orange
    case 3..<5:
      return .red
    case 5..<7:
      return .purple
    case 7..<Double.greatestFiniteMagnitude:
      return .indigo
    default:
      return .gray
    }
  }
}
