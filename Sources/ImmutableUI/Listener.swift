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

import ImmutableData

@MainActor final package class Listener<State, Action, each Dependency, Output> where State : Sendable, Action : Sendable, repeat each Dependency : Sendable, Output : Sendable {
  private var id: AnyHashable?
  private var label: String?
  private var filter: (@Sendable (State, Action) -> Bool)?
  private var dependencySelector: (repeat DependencySelector<State, each Dependency>)
  private var outputSelector: OutputSelector<State, Output>
  
  private weak var store: AnyObject?
  private var listener: AsyncListener<State, Action, repeat each Dependency, Output>?
  private var task: Task<Void, any Error>?
  
  package init(
    id: some Hashable,
    label: String? = nil,
    filter isIncluded: (@Sendable (State, Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<State, each Dependency>,
    outputSelector: OutputSelector<State, Output>
  ) {
    self.id = AnyHashable(id)
    self.label = label
    self.filter = isIncluded
    self.dependencySelector = (repeat each dependencySelector)
    self.outputSelector = outputSelector
  }
  
  package init(
    label: String? = nil,
    filter isIncluded: (@Sendable (State, Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<State, each Dependency>,
    outputSelector: OutputSelector<State, Output>
  ) {
    self.id = nil
    self.label = label
    self.filter = isIncluded
    self.dependencySelector = (repeat each dependencySelector)
    self.outputSelector = outputSelector
  }
  
  deinit {
    self.task?.cancel()
  }
}

extension Listener {
  package var output: Output {
    guard let output = self.listener?.output else { fatalError("missing output") }
    return output
  }
}

extension Listener {
  package func update(
    id: some Hashable,
    label: String? = nil,
    filter isIncluded: (@Sendable (State, Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<State, each Dependency>,
    outputSelector: OutputSelector<State, Output>
  ) {
    let id = AnyHashable(id)
    if self.id != id {
      self.id = id
      self.label = label
      self.filter = isIncluded
      self.dependencySelector = (repeat each dependencySelector)
      self.outputSelector = outputSelector
      self.store = nil
    }
  }
}

extension Listener {
  package func update(
    label: String? = nil,
    filter isIncluded: (@Sendable (State, Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<State, each Dependency>,
    outputSelector: OutputSelector<State, Output>
  ) {
    if self.id != nil {
      self.id = nil
      self.label = label
      self.filter = isIncluded
      self.dependencySelector = (repeat each dependencySelector)
      self.outputSelector = outputSelector
      self.store = nil
    }
  }
}

extension Listener {
  package func listen(to store: some ImmutableData.Selector<State> & ImmutableData.Streamer<State, Action> & AnyObject) {
    if self.store !== store {
      self.store = store
      
      let listener = AsyncListener<State, Action, repeat each Dependency, Output>(
        label: self.label,
        filter: self.filter,
        dependencySelector: repeat each self.dependencySelector,
        outputSelector: self.outputSelector
      )
      listener.update(with: store)
      self.listener = listener
      
      let stream = store.makeStream()
      
      self.task?.cancel()
      self.task = Task {
        try await listener.listen(
          to: stream,
          with: store
        )
      }
    }
  }
}
