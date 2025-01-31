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

import AsyncSequenceTestUtils
import ImmutableData
import ImmutableUI
import Observation
import Testing

extension Testing.Confirmation {
  fileprivate func confirm() {
    self.confirm(count: 1)
  }
}

extension Array {
  final fileprivate class Error : Swift.Error {
    let message: String
    
    init(message: String = "") {
      self.message = message
    }
  }
}

extension Array {
  fileprivate mutating func throwingRemoveFirst() throws -> Element {
    guard
      self.isEmpty == false
    else {
      throw Self.Error(message: "empty array")
    }
    return self.removeFirst()
  }
}

extension Array {
  subscript(throwing index: Int) -> Element {
    get throws {
      guard
        0 <= index,
        index < self.count
      else {
        throw Self.Error(message: "out of bounds at index: \(index)")
      }
      return self[index]
    }
  }
}

extension Listener {
  fileprivate func waitForChange() async {
    await withCheckedContinuation { continuation in
      withObservationTracking {
        let _ = self.output
      } onChange: {
        continuation.resume()
      }
    }
  }
}

extension Listener {
  fileprivate func onChange(_ onChange: @escaping @Sendable () -> Void) {
    withObservationTracking {
      let _ = self.output
    } onChange: {
      onChange()
    }
  }
}

final fileprivate class StateTestDouble : Sendable {
  
}

final fileprivate class ActionTestDouble : Sendable {
  
}

@MainActor final fileprivate class StoreTestDouble : Sendable {
  typealias State = StateTestDouble
  typealias Action = ActionTestDouble
  
  var sequence: AsyncSequenceTestDouble<(oldState: StateTestDouble, action: ActionTestDouble)>?
  var parameterAction = Array<ActionTestDouble>()
  var returnState = Array<StateTestDouble>()
  
  init() {
    
  }
}

extension StoreTestDouble {
  func dispatch(action: Action) async {
    guard let sequence = self.sequence else { fatalError() }
    self.parameterAction.append(action)
    let state = StateTestDouble()
    self.returnState.append(state)
    await sequence.iterator.resume(returning: (state, action))
  }
}

extension StoreTestDouble : ImmutableData.Selector {
  func select<T>(_ selector: @Sendable (StateTestDouble) -> T) -> T where T : Sendable {
    let state = StateTestDouble()
    self.returnState.append(state)
    return selector(state)
  }
}

extension StoreTestDouble : ImmutableData.Streamer {
  func makeStream() -> AsyncSequenceTestDouble<(oldState: StateTestDouble, action: ActionTestDouble)>{
    let sequence = AsyncSequenceTestDouble<(oldState: StateTestDouble, action: ActionTestDouble)>()
    self.sequence = sequence
    return sequence
  }
}

final fileprivate class FilterTestDouble : @unchecked Sendable {
  var state = Array<StateTestDouble>()
  var action = Array<ActionTestDouble>()
  let filter: Bool
  
  init(_ filter: Bool) {
    self.filter = filter
  }
}

extension FilterTestDouble {
  func filter(
    state: StateTestDouble,
    action: ActionTestDouble
  ) -> Bool {
    self.state.append(state)
    self.action.append(action)
    return self.filter
  }
}

final fileprivate class DependencyTestDouble : Sendable {
  
}

final fileprivate class DependencySelectTestDouble: @unchecked Sendable {
  var state = Array<StateTestDouble>()
  var dependency = Array<DependencyTestDouble>()
}

extension DependencySelectTestDouble {
  func select(state: StateTestDouble) -> DependencyTestDouble {
    self.state.append(state)
    let dependency = DependencyTestDouble()
    self.dependency.append(dependency)
    return dependency
  }
}

final fileprivate class DependencyDidChangeTestDouble: @unchecked Sendable {
  var parameterLHS = Array<DependencyTestDouble>()
  var parameterRHS = Array<DependencyTestDouble>()
  let didChange: Bool
  
  init(_ didChange: Bool) {
    self.didChange = didChange
  }
}

extension DependencyDidChangeTestDouble {
  func didChange(lhs: DependencyTestDouble, rhs: DependencyTestDouble) -> Bool {
    self.parameterLHS.append(lhs)
    self.parameterRHS.append(rhs)
    return self.didChange
  }
}

final fileprivate class OutputTestDouble : Sendable {
  
}

final fileprivate class OutputSelectTestDouble: @unchecked Sendable {
  var state = Array<StateTestDouble>()
  var output = Array<OutputTestDouble>()
}

extension OutputSelectTestDouble {
  func select(state: StateTestDouble) -> OutputTestDouble {
    self.state.append(state)
    let output = OutputTestDouble()
    self.output.append(output)
    return output
  }
}

final fileprivate class OutputDidChangeTestDouble: @unchecked Sendable {
  var parameterLHS = Array<OutputTestDouble>()
  var parameterRHS = Array<OutputTestDouble>()
  let didChange: Bool
  
  init(_ didChange: Bool) {
    self.didChange = didChange
  }
}

extension OutputDidChangeTestDouble {
  func didChange(lhs: OutputTestDouble, rhs: OutputTestDouble) -> Bool {
    self.parameterLHS.append(lhs)
    self.parameterRHS.append(rhs)
    return self.didChange
  }
}

@Suite final actor ListenerTests : Sendable {
  
}

extension ListenerTests {
  @Test func outputDidChange() async throws {
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, OutputTestDouble>(
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 3])
      
      await listener.update(
        id: 2,
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 1])
    }
  }
}

extension ListenerTests {
  @Test func outputDidNotChange() async throws {
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, OutputTestDouble>(
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 2,
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func oneDependencyDidChangeOutputDidChange() async throws {
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 3])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 1])
    }
  }
}

extension ListenerTests {
  @Test func oneDependencyDidNotChangeOutputDidChange() async throws {
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func oneDependencyDidChangeOutputDidNotChange() async throws {
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func oneDependencyDidNotChangeOutputDidNotChange() async throws {
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func twoDependenciesDidChangeOutputDidChange() async throws {
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(true)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 3])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 12])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 13])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 1])
    }
  }
}

extension ListenerTests {
  @Test func twoDependenciesDidNotChangeOutputDidChange() async throws {
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(false)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 0])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 1])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)

      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 2])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 3])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 10])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 4])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 5])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func twoDependenciesDidChangeOutputDidNotChange() async throws {
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(true)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 12])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 13])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func twoDependenciesDidNotChangeOutputDidNotChange() async throws {
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(false)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 0])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 1])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 2])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 3])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 10])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 4])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 5])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterOutputDidChange() async throws {
    let filter = FilterTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, OutputTestDouble>(
      filter: filter.filter,
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterOutputDidNotChange() async throws {
    let filter = FilterTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, OutputTestDouble>(
      filter: filter.filter,
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterOneDependencyDidChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(false)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)

      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterOneDependencyDidNotChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(false)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)

      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterOneDependencyDidChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(false)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)

      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterOneDependencyDidNotChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(false)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)

      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(dependencySelect.state.isEmpty)
      
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterTwoDependenciesDidNotChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(false)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(false)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterTwoDependenciesDidNotChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(false)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(false)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterTwoDependenciesDidChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(false)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(true)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func falseFilterTwoDependenciesDidChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(false)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(true)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(lastDependencySelect.state.isEmpty)

      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterOutputDidChange() async throws {
    let filter = FilterTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, OutputTestDouble>(
      filter: filter.filter,
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 3])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 1])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterOutputDidNotChange() async throws {
    let filter = FilterTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, OutputTestDouble>(
      filter: filter.filter,
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterOneDependencyDidChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(true)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 3])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 1])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterOneDependencyDidNotChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(true)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterOneDependencyDidChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(true)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterOneDependencyDidNotChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(true)
    let dependencySelect = DependencySelectTestDouble()
    let dependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: dependencySelect.select,
        didChange: dependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 0])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 1])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 2])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 3])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: dependencySelect.select,
          didChange: dependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await dependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(dependencySelect.state.isEmpty)
      
      #expect(try dependencyDidChange.parameterLHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 4])
      #expect(try dependencyDidChange.parameterRHS.throwingRemoveFirst() === dependencySelect.dependency[throwing: 5])
      #expect(dependencyDidChange.parameterLHS.isEmpty)
      #expect(dependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterTwoDependenciesDidChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(true)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(true)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 3])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 1) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 10])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 12])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 13])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 1])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterTwoDependenciesDidNotChangeOutputDidChange() async throws {
    let filter = FilterTestDouble(true)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(false)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(true)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(true)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 0])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 1])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 2])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 3])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 10])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 4])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 5])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterTwoDependenciesDidChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(true)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(true)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(true)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 0])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 1])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try firstOutputDidChange.parameterLHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 2])
      #expect(try firstOutputDidChange.parameterRHS.throwingRemoveFirst() === firstOutputSelect.output[throwing: 3])
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 2])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 10])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 12])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 13])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try lastOutputDidChange.parameterLHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 0])
      #expect(try lastOutputDidChange.parameterRHS.throwingRemoveFirst() === lastOutputSelect.output[throwing: 1])
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}

extension ListenerTests {
  @Test func trueFilterTwoDependenciesDidNotChangeOutputDidNotChange() async throws {
    let filter = FilterTestDouble(true)
    let firstDependencySelect = DependencySelectTestDouble()
    let firstDependencyDidChange = DependencyDidChangeTestDouble(false)
    let lastDependencySelect = DependencySelectTestDouble()
    let lastDependencyDidChange = DependencyDidChangeTestDouble(false)
    let firstOutputSelect = OutputSelectTestDouble()
    let firstOutputDidChange = OutputDidChangeTestDouble(false)
    let lastOutputSelect = OutputSelectTestDouble()
    let lastOutputDidChange = OutputDidChangeTestDouble(false)
    let listener = await Listener<StateTestDouble, ActionTestDouble, DependencyTestDouble, DependencyTestDouble, OutputTestDouble>(
      filter: filter.filter,
      dependencySelector: DependencySelector(
        select: firstDependencySelect.select,
        didChange: firstDependencyDidChange.didChange
      ),
      DependencySelector(
        select: lastDependencySelect.select,
        didChange: lastDependencyDidChange.didChange
      ),
      outputSelector: OutputSelector(
        select: firstOutputSelect.select,
        didChange: firstOutputDidChange.didChange
      )
    )
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 0])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 1])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 0])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 1])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 0])
    }
    do {
      let store = await StoreTestDouble()
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 0])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 1])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await firstOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 2])
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 1,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: firstOutputSelect.select,
          didChange: firstOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 3])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 0])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 4])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 5])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 2])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 3])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 2])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 3])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(firstOutputSelect.state.isEmpty)
      
      #expect(firstOutputDidChange.parameterLHS.isEmpty)
      #expect(firstOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === firstOutputSelect.output[throwing: 1])
      
      await listener.update(
        id: 2,
        filter: filter.filter,
        dependencySelector: DependencySelector(
          select: firstDependencySelect.select,
          didChange: firstDependencyDidChange.didChange
        ),
        DependencySelector(
          select: lastDependencySelect.select,
          didChange: lastDependencyDidChange.didChange
        ),
        outputSelector: OutputSelector(
          select: lastOutputSelect.select,
          didChange: lastOutputDidChange.didChange
        )
      )
      await listener.listen(to: store)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 6])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 7])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try await lastOutputSelect.state.throwingRemoveFirst() === store.returnState[throwing: 8])
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
      
      await confirmation(expectedCount: 0) { onChange in
        await listener.onChange(onChange.confirm)
        await store.dispatch(action: ActionTestDouble())
      }
      
      #expect(try await filter.state.throwingRemoveFirst() === store.returnState[throwing: 9])
      #expect(filter.state.isEmpty)
      
      #expect(try await filter.action.throwingRemoveFirst() === store.parameterAction[throwing: 1])
      #expect(filter.action.isEmpty)
      
      #expect(try await firstDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 10])
      #expect(firstDependencySelect.state.isEmpty)
      
      #expect(try await lastDependencySelect.state.throwingRemoveFirst() === store.returnState[throwing: 11])
      #expect(lastDependencySelect.state.isEmpty)
      
      #expect(try firstDependencyDidChange.parameterLHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 4])
      #expect(try firstDependencyDidChange.parameterRHS.throwingRemoveFirst() === firstDependencySelect.dependency[throwing: 5])
      #expect(firstDependencyDidChange.parameterLHS.isEmpty)
      #expect(firstDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(try lastDependencyDidChange.parameterLHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 4])
      #expect(try lastDependencyDidChange.parameterRHS.throwingRemoveFirst() === lastDependencySelect.dependency[throwing: 5])
      #expect(lastDependencyDidChange.parameterLHS.isEmpty)
      #expect(lastDependencyDidChange.parameterRHS.isEmpty)
      
      #expect(lastOutputSelect.state.isEmpty)
      
      #expect(lastOutputDidChange.parameterLHS.isEmpty)
      #expect(lastOutputDidChange.parameterRHS.isEmpty)
      
      #expect(try await listener.output === lastOutputSelect.output[throwing: 0])
    }
  }
}
