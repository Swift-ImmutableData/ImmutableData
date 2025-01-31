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
import SwiftUI

/// A dynamic property that dispatches events that could affect change on the global state of our application.
///
/// Product engineers would construct a `Dispatcher` with a key path after a store has been set in this environment:
///
/// ```swift
/// struct ContentView: View {
///   @ImmutableUI.Selector(
///     \.store,
///      outputSelector: OutputSelector(
///       select: { $0 },
///       didChange: { $0 != $1 }
///      )
///   ) var value
///
///   @ImmutableUI.Dispatcher(\.store) var dispatcher
///
///   func didTapIncrementButton() {
///     do {
///       try self.dispatcher.dispatch(action: .didTapIncrementButton)
///     } catch {
///       print(error)
///     }
///   }
///
///   func didTapDecrementButton() {
///     do {
///       try self.dispatcher.dispatch(action: .didTapDecrementButton)
///     } catch {
///       print(error)
///     }
///   }
///
///   var body: some View {
///     Stepper {
///       Text("Value: \(self.value)")
///     } onIncrement: {
///       self.didTapIncrementButton()
///     } onDecrement: {
///       self.didTapDecrementButton()
///     }
///   }
/// }
/// ```
///
/// - Note: `Provider` does not explicitly require its store to be an instance of `ImmutableData.Store`.
///
/// - SeeAlso: The `Dispatcher` dynamic property serves a similar role as the [`useDispatch`](https://react-redux.js.org/api/hooks#usedispatch) hook from React Redux.
@MainActor @propertyWrapper public struct Dispatcher<Store>: DynamicProperty where Store: ImmutableData.Dispatcher {
  @Environment private var store: Store
  
  /// Constructs a `Dispatcher`.
  ///
  /// - Parameter keyPath: A key path to a store.
  public init(_ keyPath: KeyPath<EnvironmentValues, Store>) {
    self._store = Environment(keyPath)
  }
  
  /// The current store of the environment property.
  public var wrappedValue: some ImmutableData.Dispatcher<Store.State, Store.Action> {
    self.store
  }
}
