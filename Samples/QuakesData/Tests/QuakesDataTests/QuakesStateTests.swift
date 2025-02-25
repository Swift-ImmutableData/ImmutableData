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

@Suite final actor QuakesStateTests {
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

extension QuakesStateTests {
  @Test(
    arguments: QuakesDataTests.product(
      ["North", "South", "East", "West"],
      [Date.distantPast, Date.now, Date.distantFuture],
      [\Quake.quakeId, \Quake.magnitude, \Quake.time],
      [SortOrder.forward, SortOrder.reverse]
    )
  ) func selectQuakesValues(
    searchText: String,
    searchDate: Date,
    partialKeyPath: PartialKeyPath<Quake> & Sendable,
    order: SortOrder
  ) {
    func test<Value>(
      searchText: String,
      searchDate: Date,
      sort partialKeyPath: PartialKeyPath<Quake> & Sendable,
      valueType: Value.Type,
      order: SortOrder
    ) where Value : Comparable {
      let keyPath = partialKeyPath as! KeyPath<Quake, Value> & Sendable
      let state = Self.state
      let values = QuakesState.selectQuakesValues(
        searchText: searchText,
        searchDate: searchDate,
        sort: keyPath,
        order: order
      )(state)
      #expect(
        values == state.quakes.data.values.filter { quake in
          let calendar = Calendar.autoupdatingCurrent
          let start = calendar.startOfDay(for: searchDate)
          let end = calendar.date(byAdding: DateComponents(day: 1), to: start) ?? start
          let range = start...end
          if range.contains(quake.time) {
            if searchText.isEmpty {
              return true
            }
            if quake.name.contains(searchText) {
              return true
            }
          }
          return false
        }.sorted(
          using: SortDescriptor(
            keyPath,
            order: order
          )
        )
      )
    }
    let valueType = type(of: partialKeyPath).valueType as! any Comparable.Type
    test(
      searchText: searchText,
      searchDate: searchDate,
      sort: partialKeyPath,
      valueType: valueType,
      order: order
    )
  }
}

extension QuakesStateTests {
  @Test(
    arguments: QuakesDataTests.product(
      ["North", "South", "East", "West"],
      [Date.distantPast, Date.now, Date.distantFuture]
    )
  ) func selectQuakes(
    searchText: String,
    searchDate: Date
  ) {
    let state = Self.state
    let values = QuakesState.selectQuakes(
      searchText: searchText,
      searchDate: searchDate
    )(state)
    #expect(
      values == state.quakes.data.filter { element in
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: searchDate)
        let end = calendar.date(byAdding: DateComponents(day: 1), to: start) ?? start
        let range = start...end
        if range.contains(element.value.time) {
          if searchText.isEmpty {
            return true
          }
          if element.value.name.contains(searchText) {
            return true
          }
        }
        return false
      }
    )
  }
}

extension QuakesStateTests {
  @Test func selectQuakesCount() {
    let state = Self.state
    let count = QuakesState.selectQuakesCount()(state)
    #expect(count == state.quakes.data.count)
  }
}

extension QuakesStateTests {
  @Test func selectQuakesStatus() {
    var state = Self.state
    #expect(QuakesState.selectQuakesStatus()(state) == nil)
    
    state.quakes.status = .empty
    #expect(QuakesState.selectQuakesStatus()(state) == .empty)
    
    state.quakes.status = .waiting
    #expect(QuakesState.selectQuakesStatus()(state) == .waiting)
    
    state.quakes.status = .success
    #expect(QuakesState.selectQuakesStatus()(state) == .success)
    
    state.quakes.status = .failure(error: "error")
    #expect(QuakesState.selectQuakesStatus()(state) == .failure(error: "error"))
  }
}

extension QuakesStateTests {
  @Test(arguments: Self.state.quakes.data.values) func selectQuake(quake: Quake) {
    let state = Self.state
    #expect(QuakesState.selectQuake(quakeId: quake.id)(state) == quake)
  }
}
