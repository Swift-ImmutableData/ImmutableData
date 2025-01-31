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

import SwiftUI

/// A component for delivering a store through environment.
///
/// Product engineers would normally construct one `Provider` component on app launch:
///
/// ```swift
/// enum Action {
///   case didTapIncrementButton
///   case didTapDecrementButton
/// }
///
/// func reducer(state: Int, action: Action) -> Int {
///   switch action {
///   case .didTapIncrementButton:
///     state + 1
///   case .didTapDecrementButton:
///     state - 1
///   }
/// }
///
/// @MainActor struct StoreKey: @preconcurrency EnvironmentKey {
///   static let defaultValue = ImmutableData.Store<Int, Action>(
///     initialState: 0,
///     reducer: { state, action in
///       fatalError()
///     }
///   )
/// }
///
/// extension EnvironmentValues {
///   var store: ImmutableData.Store<Int, Action> {
///     get {
///       self[StoreKey.self]
///     }
///     set {
///       self[StoreKey.self] = newValue
///     }
///   }
/// }
///
/// @main
/// struct MyApp: App {
///   @State var store = Store(
///     initialState: 0,
///     reducer: reducer
///   )
///
///   var body: some Scene {
///     WindowGroup {
///       ImmutableUI.Provider(
///         \.store,
///         self.store
///       ) {
///         ContentView()
///       }
///     }
///   }
/// }
/// ```
///
/// - Note: `Provider` does not explicitly require its store to be an instance of `ImmutableData.Store`.
///
/// - SeeAlso: The `Provider` component serves a similar role as the [`Provider`](https://react-redux.js.org/api/provider) component in React Redux.
@MainActor public struct Provider<Store, Content> where Content: View {
  private let keyPath: WritableKeyPath<EnvironmentValues, Store>
  private let store: Store
  private let content: Content
  
  /// Constructs a `Provider`.
  ///
  /// - Parameter keyPath: A key path that indicates the property of the `EnvironmentValues` structure to update.
  /// - Parameter store: The store to set in this component’s environment.
  /// - Parameter content: A closure that constructs a component.
  ///
  /// - Note: `Provider` does not explicitly require its store to be an instance of `ImmutableData.Store`.
  public init(
    _ keyPath: WritableKeyPath<EnvironmentValues, Store>,
    _ store: Store,
    @ViewBuilder content: () -> Content
  ) {
    self.keyPath = keyPath
    self.store = store
    self.content = content()
  }
}

extension Provider: View {
  public var body: some View {
    self.content.environment(self.keyPath, self.store)
  }
}
