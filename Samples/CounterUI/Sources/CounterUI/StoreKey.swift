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

import CounterData
import ImmutableData
import ImmutableUI
import SwiftUI

//  https://github.com/apple/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md

extension ImmutableUI.Provider {
  public init(
    _ store: Store,
    @ViewBuilder content: () -> Content
  ) where Store == ImmutableData.Store<CounterState, CounterAction> {
    self.init(
      \.store,
       store,
       content: content
    )
  }
}

extension ImmutableUI.Dispatcher {
  public init() where Store == ImmutableData.Store<CounterState, CounterAction> {
    self.init(\.store)
  }
}

extension ImmutableUI.Selector {
  public init(
    id: some Hashable,
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<Store.State, each Dependency>,
    outputSelector: OutputSelector<Store.State, Output>
  ) where Store == ImmutableData.Store<CounterState, CounterAction> {
    self.init(
      \.store,
       id: id,
       label: label,
       filter: isIncluded,
       dependencySelector: repeat each dependencySelector,
       outputSelector: outputSelector
    )
  }
}

extension ImmutableUI.Selector {
  public init(
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<Store.State, each Dependency>,
    outputSelector: OutputSelector<Store.State, Output>
  ) where Store == ImmutableData.Store<CounterState, CounterAction> {
    self.init(
      \.store,
       label: label,
       filter: isIncluded,
       dependencySelector: repeat each dependencySelector,
       outputSelector: outputSelector
    )
  }
}

@MainActor fileprivate struct StoreKey : @preconcurrency EnvironmentKey {
  static let defaultValue = ImmutableData.Store(
    initialState: CounterState(),
    reducer: CounterReducer.reduce
  )
}

extension EnvironmentValues {
  fileprivate var store: ImmutableData.Store<CounterState, CounterAction> {
    get {
      self[StoreKey.self]
    }
    set {
      self[StoreKey.self] = newValue
    }
  }
}
