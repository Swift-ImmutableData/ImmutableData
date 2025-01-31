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

/// The “Fundamental Theorem of `ImmutableData`”.
///
/// A `Reducer` is a pure function free of side effects.
///
/// *All* transformations on the global state of our application *must* happen through a root reducer.
///
/// - Throws: An `Error` indicating this `(State, Action)` pair led to a recoverable error and state was not transformed.
///
/// - SeeAlso: The `Reducer` type serves a similar role as the [Reducer](https://redux.js.org/understanding/thinking-in-redux/glossary#reducer) type in Redux.
public typealias Reducer<State, Action> = @Sendable (State, Action) throws -> State where State: Sendable, Action: Sendable

/// An object to save the current state of our data models.
///
/// Construct a `Store` with an initial state and a root reducer:
///
/// ```swift
/// enum Action {
///   case increment
/// }
///
/// func reducer(state: Int, action: Action) -> Int {
///   state + 1
/// }
///
/// let store = Store(
///   initialState: 0,
///   reducer: reducer
/// )
///
/// try store.dispatch(action: .increment)
///
/// print(store.state)
/// // Prints "1"
/// ```
///
/// - SeeAlso: The `Store` object serves a similar role as the [Store](https://redux.js.org/understanding/thinking-in-redux/glossary#store) object in Redux.
@MainActor final public class Store<State, Action> where State: Sendable, Action: Sendable {
  private let registrar = StreamRegistrar<(oldState: State, action: Action)>()
  
  private var state: State
  private let reducer: Reducer<State, Action>
  
  /// Constructs a `Store`.
  ///
  /// - Parameter state: The initial state of our application.
  /// - Parameter reducer: The root reducer of our application.
  public init(
    initialState state: State,
    reducer: @escaping Reducer<State, Action>
  ) {
    self.state = state
    self.reducer = reducer
  }
}

extension Store: Dispatcher {
  public func dispatch(action: Action) throws {
    let oldState = self.state
    self.state = try self.reducer(self.state, action)
    self.registrar.yield((oldState: oldState, action: action))
  }
  
  public func dispatch(thunk: @Sendable (Store, Store) throws -> Void) rethrows {
    try thunk(self, self)
  }
  
  public func dispatch(thunk: @Sendable (Store, Store) async throws -> Void) async rethrows {
    try await thunk(self, self)
  }
}

extension Store: Selector {
  public func select<T>(_ selector: @Sendable (State) -> T) -> T where T: Sendable {
    selector(self.state)
  }
}

extension Store: Streamer {
  public func makeStream() -> AsyncStream<(oldState: State, action: Action)> {
    self.registrar.makeStream()
  }
}
