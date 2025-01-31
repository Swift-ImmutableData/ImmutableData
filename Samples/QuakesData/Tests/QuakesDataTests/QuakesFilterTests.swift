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
import QuakesData
import Testing

@Suite final actor QuakesFilterTests {
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

extension QuakesFilterTests {
  private static var filterCategoriesValuesIncludedArguments: Array<QuakesAction> {
    var array = Array<QuakesAction>()
    array.append(
      .ui(.quakeList(.onTapDeleteSelectedQuakeButton(quakeId: "quakeId")))
    )
    array.append(
      .ui(.quakeList(.onTapDeleteAllQuakesButton))
    )
    array.append(
      .data(.persistentSession(.localStore(.didFetchQuakes(result: .success(quakes: [])))))
    )
    array.append(
      .data(.persistentSession(.remoteStore(.didFetchQuakes(result: .success(quakes: [])))))
    )
    return array
  }
}

extension QuakesFilterTests {
  private static var filterCategoriesValuesNotIncludedArguments: Array<QuakesAction> {
    var array = Array<QuakesAction>()
    array.append(
      .ui(.quakeList(.onAppear))
    )
    array.append(
      .ui(.quakeList(.onTapRefreshQuakesButton(range: .allHour)))
    )
    array.append(
      .ui(.quakeList(.onTapRefreshQuakesButton(range: .allDay)))
    )
    array.append(
      .ui(.quakeList(.onTapRefreshQuakesButton(range: .allWeek)))
    )
    array.append(
      .ui(.quakeList(.onTapRefreshQuakesButton(range: .allMonth)))
    )
    return array
  }
}

extension QuakesFilterTests {
  @Test(arguments: Self.filterCategoriesValuesIncludedArguments) func filterQuakesIncluded(action: QuakesAction) {
    let isIncluded = QuakesFilter.filterQuakes()(Self.state, action)
    #expect(isIncluded)
  }
}

extension QuakesFilterTests {
  @Test(arguments: Self.filterCategoriesValuesNotIncludedArguments) func filterQuakesNotIncluded(action: QuakesAction) {
    let isIncluded = QuakesFilter.filterQuakes()(Self.state, action)
    #expect(isIncluded == false)
  }
}
