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

/// An interface that selects a slice of the global state of our application.
public protocol Selector<State>: Sendable {
  
  /// The global state of our application.
  ///
  /// - Important: `State` values are modeled as immutable value-types -- *not* mutable reference-types.
  ///
  /// - SeeAlso: The `State` type serves a similar role as the [State](https://redux.js.org/understanding/thinking-in-redux/glossary#state) type in Redux.
  associatedtype State: Sendable
  
  /// Select a slice of the global state of our application.
  ///
  /// - Parameter selector: A slice of the global state of our application.
  ///
  /// - Returns: A slice of the global state of our application.
  ///
  /// - Important: Selectors are *pure* functions: free of side effects.
  ///
  /// - SeeAlso: The `selector` function serves a similar role as [Selector](https://redux.js.org/usage/deriving-data-selectors#calculating-derived-data-with-selectors) functions in Redux.
  @MainActor func select<T>(_ selector: @Sendable (Self.State) -> T) -> T where T: Sendable
}

extension Selector {
  
  /// A convenience function for returning the global state of our application with no transformation applied.
  ///
  /// For the most part, product engineers should prefer *scoping* the slices of state returned with ``select(_:)``.
  ///
  /// A component graph that depends on the entire global state of our application could compute its `body` properties more often than necessary.
  ///
  /// - Returns: The global state of our application.
  @MainActor public var state: State {
    self.select { state in state }
  }
}
