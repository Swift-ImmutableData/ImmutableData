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
  ) where Store == ImmutableData.Store<CounterState, CounterAction>, repeat each Dependency : Equatable, Output : Equatable {
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
  ) where Store == ImmutableData.Store<CounterState, CounterAction>, repeat each Dependency : Equatable, Output : Equatable {
    self.init(
      label: label,
      filter: isIncluded,
      dependencySelector: repeat DependencySelector(select: each dependencySelector),
      outputSelector: OutputSelector(select: outputSelector)
    )
  }
}

@MainActor @propertyWrapper struct SelectValue : DynamicProperty {
  @ImmutableUI.Selector(outputSelector: CounterState.selectValue()) var wrappedValue
  
  init() {
    
  }
}
