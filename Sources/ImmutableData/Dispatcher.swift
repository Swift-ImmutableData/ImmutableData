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

/// An interface that dispatches events that could affect change on the global state of our application.
public protocol Dispatcher<State, Action>: Sendable {
  
  /// The global state of our application.
  ///
  /// - Important: `State` values are modeled as immutable value-types -- *not* mutable reference-types.
  ///
  /// - SeeAlso: The `State` type serves a similar role as the [State](https://redux.js.org/understanding/thinking-in-redux/glossary#state) type in Redux.
  associatedtype State: Sendable
  
  /// An event that could affect change on the global state of our application.
  ///
  /// Some examples:
  /// * A user tapped on a button component.
  /// * A local database returned a set of data models.
  /// * A remote server sent a push notification.
  ///
  ///
  /// - Important: `Action` values are modeled as immutable value-types -- *not* mutable reference-types.
  ///
  /// - SeeAlso: The `Action` type serves a similar role as the [Action](https://redux.js.org/understanding/thinking-in-redux/glossary#action) type in Redux.
  associatedtype Action: Sendable
  
  /// A ``/ImmutableData/Dispatcher`` type for affecting change on the global state of our application.
  ///
  /// This type is passed to the `dispatch(thunk:)` functions.
  ///
  /// This type can be the same type we just dispatched from -- but this is not explicitly required.
  associatedtype Dispatcher: ImmutableData.Dispatcher<Self.State, Self.Action>
  
  /// A ``/ImmutableData/Selector`` type for selecting a slice of the global state of our application.
  ///
  /// This type is passed to the `dispatch(thunk:)` functions.
  ///
  /// This type can be the same type we just dispatched from -- but this is not explicitly required.
  associatedtype Selector: ImmutableData.Selector<Self.State>
  
  /// Dispatch an event that could affect change on the global state of our application.
  ///
  ///
  /// - Parameter action: An event that could affect change on the global state of our application.
  ///
  /// - Throws: An `Error` from the root reducer.
  ///
  /// - SeeAlso: The `dispatch(action:)` function serves a similar role as the [`dispatch(action)`](https://redux.js.org/api/store#dispatchaction) function in Redux.
  @MainActor func dispatch(action: Action) throws
  
  /// Dispatch a unit of work that could include side effects.
  ///
  /// - Parameter thunk: A unit of work that could include side effects.
  ///
  /// - SeeAlso: The `dispatch(thunk:)` functions serve a similar role as the [Thunk](https://redux.js.org/usage/side-effects-approaches#thunks) middleware in Redux.
  @MainActor func dispatch(thunk: @Sendable (Self.Dispatcher, Self.Selector) throws -> Void) rethrows
  
  /// Dispatch a unit of work that could include side effects.
  ///
  /// - Parameter thunk: A unit of work that could include side effects.
  ///
  /// - SeeAlso: The `dispatch(thunk:)` functions serve a similar role as the [Thunk](https://redux.js.org/usage/side-effects-approaches#thunks) middleware in Redux.
  @MainActor func dispatch(thunk: @Sendable (Self.Dispatcher, Self.Selector) async throws -> Void) async rethrows
}
