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
import CowBox
import Foundation

@CowBox(init: .withPackage) public struct QuakesState: Hashable, Sendable {
  package var quakes: Quakes
}

extension QuakesState {
  public init() {
    self.init(
      quakes: Quakes()
    )
  }
}

extension QuakesState {
  @CowBox(init: .withPackage) package struct Quakes: Hashable, Sendable {
    package var data: TreeDictionary<Quake.ID, Quake> = [:]
    package var status: Status? = nil
  }
}

extension Quake {
  fileprivate static func filter(
    searchText: String,
    searchDate: Date
  ) -> @Sendable (Self) -> Bool {
    let calendar = Calendar.autoupdatingCurrent
    let start = calendar.startOfDay(for: searchDate)
    let end = calendar.date(byAdding: DateComponents(day: 1), to: start) ?? start
    let range = start...end
    return { quake in
      if range.contains(quake.time) {
        if searchText.isEmpty {
          return true
        }
        if quake.name.contains(searchText) {
          return true
        }
      }
      return false
    }
  }
}

extension QuakesState {
  fileprivate func selectQuakesValues(
    filter isIncluded: (Quake) -> Bool,
    sort descriptor: SortDescriptor<Quake>
  ) -> Array<Quake> {
    self.quakes.data.values.filter(isIncluded).sorted(using: descriptor)
  }
}

extension QuakesState {
  fileprivate func selectQuakesValues(
    searchText: String,
    searchDate: Date,
    sort keyPath: KeyPath<Quake, some Comparable & Sendable> & Sendable,
    order: SortOrder = .forward
  ) -> Array<Quake> {
    self.selectQuakesValues(
      filter: Quake.filter(
        searchText: searchText,
        searchDate: searchDate
      ),
      sort: SortDescriptor(
        keyPath,
        order: order
      )
    )
  }
}

extension QuakesState {
  public static func selectQuakesValues(
    searchText: String,
    searchDate: Date,
    sort keyPath: KeyPath<Quake, some Comparable & Sendable> & Sendable,
    order: SortOrder = .forward
  ) -> @Sendable (Self) -> Array<Quake> {
    { state in
      state.selectQuakesValues(
        searchText: searchText,
        searchDate: searchDate,
        sort: keyPath,
        order: order
      )
    }
  }
}

extension QuakesState {
  fileprivate func selectQuakes(filter isIncluded: (Quake) -> Bool) -> TreeDictionary<Quake.ID, Quake> {
    self.quakes.data.filter { isIncluded($0.value) }
  }
}

extension QuakesState {
  fileprivate func selectQuakes(
    searchText: String,
    searchDate: Date
  ) -> TreeDictionary<Quake.ID, Quake> {
    self.selectQuakes(
      filter: Quake.filter(
        searchText: searchText,
        searchDate: searchDate
      )
    )
  }
}

extension QuakesState {
  public static func selectQuakes(
    searchText: String,
    searchDate: Date
  ) -> @Sendable (Self) -> TreeDictionary<Quake.ID, Quake> {
    { state in
      state.selectQuakes(
        searchText: searchText,
        searchDate: searchDate
      )
    }
  }
}

extension QuakesState {
  fileprivate func selectQuakesCount() -> Int {
    self.quakes.data.count
  }
}

extension QuakesState {
  public static func selectQuakesCount() -> @Sendable (Self) -> Int {
    { state in state.selectQuakesCount() }
  }
}

extension QuakesState {
  fileprivate func selectQuakesStatus() -> Status? {
    self.quakes.status
  }
}

extension QuakesState {
  public static func selectQuakesStatus() -> @Sendable (Self) -> Status? {
    { state in state.selectQuakesStatus() }
  }
}

extension QuakesState {
  fileprivate func selectQuake(quakeId: Quake.ID?) -> Quake? {
    guard
      let quakeId = quakeId
    else {
      return nil
    }
    return self.quakes.data[quakeId]
  }
}

extension QuakesState {
  public static func selectQuake(quakeId: Quake.ID?) -> @Sendable (Self) -> Quake? {
    { state in state.selectQuake(quakeId: quakeId) }
  }
}
