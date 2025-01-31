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

/// An interface that provides asynchronous updates when events are dispatched.
public protocol Streamer<State, Action>: Sendable {
  
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
  /// - Important: `Action` values are modeled as immutable value-types -- *not* mutable reference-types.
  ///
  /// - SeeAlso: The `Action` type serves a similar role as the [Action](https://redux.js.org/understanding/thinking-in-redux/glossary#action) type in Redux.
  associatedtype Action: Sendable
  
  /// An asynchronous sequence of values.
  ///
  /// After a ``Dispatcher`` dispatches an event and our root reducer returns a new state value, a new value is added to this list.
  ///
  /// The `Element` type is equal to `(Self.State, Self.Action)`.
  ///
  /// The state value is the *previous* state of our system -- *before* an action value was dispatched to our root reducer.
  associatedtype Stream: AsyncSequence, Sendable where Self.Stream.Element == (oldState: Self.State, action: Self.Action)
  
  /// Constructs an asynchronous sequence of values.
  ///
  /// - Returns: An asynchronous sequence of values.
  ///
  /// - SeeAlso: The `makeStream()` function serves a similar role as the [`subscribe(listener)`](https://redux.js.org/api/store#subscribelistener) function in Redux and the [Listener](https://redux.js.org/usage/side-effects-approaches#listeners) middleware in Redux Toolkit.
  @MainActor func makeStream() -> Self.Stream
}
