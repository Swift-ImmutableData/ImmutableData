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
import ImmutableData
import ImmutableUI
import QuakesData
import SwiftUI

extension ImmutableUI.DependencySelector {
  init(select: @escaping @Sendable (State) -> Dependency) where Dependency : Equatable {
    self.init(select: select, didChange: { $0 != $1 })
  }
}

extension ImmutableUI.OutputSelector {
  init(select: @escaping @Sendable (State) -> Output) where Output : Equatable {
    self.init(select: select, didChange: { $0 != $1 })
  }
}

extension ImmutableUI.Selector {
  init(
    id: some Hashable,
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat @escaping @Sendable (Store.State) -> each Dependency,
    outputSelector: @escaping @Sendable (Store.State) -> Output
  ) where Store == ImmutableData.Store<QuakesState, QuakesAction>, repeat each Dependency : Equatable, Output : Equatable {
    self.init(
       id: id,
       label: label,
       filter: isIncluded,
       dependencySelector: repeat DependencySelector(select: each dependencySelector),
       outputSelector: OutputSelector(select: outputSelector)
    )
  }
}

extension ImmutableUI.Selector {
  init(
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat @escaping @Sendable (Store.State) -> each Dependency,
    outputSelector: @escaping @Sendable (Store.State) -> Output
  ) where Store == ImmutableData.Store<QuakesState, QuakesAction>, repeat each Dependency : Equatable, Output : Equatable {
    self.init(
       label: label,
       filter: isIncluded,
       dependencySelector: repeat DependencySelector(select: each dependencySelector),
       outputSelector: OutputSelector(select: outputSelector)
    )
  }
}

@MainActor @propertyWrapper struct SelectQuakes: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<QuakesState, QuakesAction>, TreeDictionary<Quake.ID, Quake>> var wrappedValue: TreeDictionary<Quake.ID, Quake>
  
  init(
    searchText: String,
    searchDate: Date
  ) {
    self._wrappedValue = ImmutableUI.Selector(
      id: ID(
        searchText: searchText,
        searchDate: searchDate
      ),
      label: "SelectQuakes(searchText: \"\(searchText)\", searchDate: \(searchDate))",
      filter: QuakesFilter.filterQuakes(),
      outputSelector: QuakesState.selectQuakes(
        searchText: searchText,
        searchDate: searchDate
      )
    )
  }
}

extension SelectQuakes {
  fileprivate struct ID : Hashable {
    let searchText: String
    let searchDate: Date
  }
}

@MainActor @propertyWrapper struct SelectQuakesValues: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<QuakesState, QuakesAction>, TreeDictionary<Quake.ID, Quake>, Array<Quake>> var wrappedValue: Array<Quake>
  
  init(
    searchText: String,
    searchDate: Date,
    sort keyPath: KeyPath<Quake, some Comparable & Sendable> & Sendable,
    order: SortOrder
  ) {
    self._wrappedValue = ImmutableUI.Selector(
      id: ID(
        searchText: searchText,
        searchDate: searchDate,
        keyPath: keyPath,
        order: order
      ),
      label: "SelectQuakesValues(searchText: \"\(searchText)\", searchDate: \(searchDate), keyPath: \(keyPath), order: \(order))",
      filter: QuakesFilter.filterQuakes(),
      dependencySelector: QuakesState.selectQuakes(
        searchText: searchText,
        searchDate: searchDate
      ),
      outputSelector: QuakesState.selectQuakesValues(
        searchText: searchText,
        searchDate: searchDate,
        sort: keyPath,
        order: order
      )
    )
  }
}

extension SelectQuakesValues {
  fileprivate struct ID<Value> : Hashable where Value : Sendable {
    let searchText: String
    let searchDate: Date
    let keyPath: KeyPath<Quake, Value>
    let order: SortOrder
  }
}

@MainActor @propertyWrapper struct SelectQuakesCount: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<QuakesState, QuakesAction>, Int>(
    label: "SelectQuakesCount",
    outputSelector: QuakesState.selectQuakesCount()
  ) var wrappedValue: Int
  
  init() {
    
  }
}

@MainActor @propertyWrapper struct SelectQuakesStatus: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<QuakesState, QuakesAction>, Status?>(
    label: "SelectQuakesStatus",
    outputSelector: QuakesState.selectQuakesStatus()
  ) var wrappedValue: Status?
  
  init() {
    
  }
}

@MainActor @propertyWrapper struct SelectQuake: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<QuakesState, QuakesAction>, Quake?> var wrappedValue: Quake?
  
  init(quakeId: String?) {
    self._wrappedValue = ImmutableUI.Selector(
      id: quakeId,
      label: "SelectQuake(quakeId: \(quakeId ?? "nil"))",
      outputSelector: QuakesState.selectQuake(quakeId: quakeId)
    )
  }
}
