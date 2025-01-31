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

//  https://github.com/apple/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md

/// A slice of the global state of our application.
///
/// - Important: `Dependency` values are modeled as immutable value-types -- *not* mutable reference-types.
public struct DependencySelector<State, Dependency>: Sendable where State: Sendable, Dependency: Sendable {
  let select: @Sendable (State) -> Dependency
  let didChange: @Sendable (Dependency, Dependency) -> Bool
  
  /// Constructs a `DependencySelector`.
  ///
  /// - Important: Selectors are *pure* functions: free of side effects.
  ///
  /// - Parameters select: A slice of the global state of our application.
  /// - Parameters didChange: Return `true` to indicate two `Dependency` values changed.
  public init(
    select: @escaping @Sendable (State) -> Dependency,
    didChange: @escaping @Sendable (Dependency, Dependency) -> Bool
  ) {
    self.select = select
    self.didChange = didChange
  }
}

/// A slice of the global state of our application.
///
/// - Important: `Output` values are modeled as immutable value-types -- *not* mutable reference-types.
public struct OutputSelector<State, Output>: Sendable where State: Sendable, Output: Sendable {
  let select: @Sendable (State) -> Output
  let didChange: @Sendable (Output, Output) -> Bool
  
  /// Constructs a `OutputSelector`.
  ///
  /// - Important: Selectors are *pure* functions: free of side effects.
  ///
  /// - Parameters select: A slice of the global state of our application.
  /// - Parameters didChange: Return `true` to indicate two `Output` values changed.
  public init(
    select: @escaping @Sendable (State) -> Output,
    didChange: @escaping @Sendable (Output, Output) -> Bool
  ) {
    self.select = select
    self.didChange = didChange
  }
}

/// A dynamic property that selects a slice of the global state of our application.
///
/// Product engineers construct `Selector` values with a key path to a store and a slice of global application state as output. When the output changes, SwiftUI updates the parts of the component hierarchy that depend on the output.
///
/// An `OutputSelector` value defines the slice of global application state needed to construct our component. This slice of state must be a *pure* function: free of side effects.
///
/// To optimize for performance, product engineers have options to reduce the amount of times output is computed.
///
/// Product engineers pass an optional parameter pack of `DependencySelector` values to determine if the output should be computed. If one of the `Dependency` values has changed, the output will be computed. If none of the `Dependency` values have changed, the output will return the cached result.
///
/// Product engineers pass an optional filter that runs on every action value dispatched to the store. If this filter returns `true`, this indicates that a `(State, Action)` pair could change an output. If this filter returns `false`, the output will return the cached result.
///
/// Over the lifetime of a SwiftUI component, it is possible for the identity of the data to change -- even if the identity of the component *itself* remains constant. An example might be a product detail page. Displaying a product detail page and changing the product id from an adjacent component should recompute the data being displayed.
///
/// Product engineers pass an optional `id` value to indicate the identity of this `Selector`. When the value of the `id` changes, any cached dependencies and outputs are reset. Conceptually, this can be thought of as similar to the `id(_:)` function used on `SwiftUI.View`.
///
/// Product engineers would construct a `Selector` with a key path after a store has been set in this environment:
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
/// - Note: `Selector` does not explicitly require its store to be an instance of `ImmutableData.Store`.
///
/// - SeeAlso: The `Selector` dynamic property serves a similar role as the [`useSelector`](https://react-redux.js.org/api/hooks#useselector) hook from React Redux and the [Reselect](https://redux.js.org/usage/deriving-data-selectors#writing-memoized-selectors-with-reselect) library.
@MainActor @propertyWrapper public struct Selector<Store, each Dependency, Output> where Store: ImmutableData.Selector, Store: ImmutableData.Streamer, Store: AnyObject, repeat each Dependency: Sendable, Output: Sendable {
  @Environment private var store: Store
  @State private var listener: Listener<Store.State, Store.Action, repeat each Dependency, Output>
  
  private let id: AnyHashable?
  private let label: String?
  private let filter: (@Sendable (Store.State, Store.Action) -> Bool)?
  private let dependencySelector: (repeat DependencySelector<Store.State, each Dependency>)
  private let outputSelector: OutputSelector<Store.State, Output>
  
  /// Constructs a `Selector`.
  ///
  /// - Parameter keyPath: A key path to a store.
  /// - Parameter id: A `Hashable` value to indicate the identity of this `Selector`.
  /// - Parameter label: An optional `String` value used for debug logging.
  /// - Parameter isIncluded: An optional filter to indicate this `(State, Action)` pair could change an output. Pass no filter to indicate all action values could change an output.
  /// - Parameter dependencySelector: A parameter pack of `DependencySelector` values to compute dependencies. Pass no values to indicate no dependencies should be computed.
  /// - Parameter outputSelector: An `OutputSelector` value to compute an output.
  public init(
    _ keyPath: KeyPath<EnvironmentValues, Store>,
    id: some Hashable,
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<Store.State, each Dependency>,
    outputSelector: OutputSelector<Store.State, Output>
  ) {
    self._store = Environment(keyPath)
    self.listener = Listener(
      id: id,
      label: label,
      filter: isIncluded,
      dependencySelector: repeat each dependencySelector,
      outputSelector: outputSelector
    )
    self.id = AnyHashable(id)
    self.label = label
    self.filter = isIncluded
    self.dependencySelector = (repeat each dependencySelector)
    self.outputSelector = outputSelector
  }
  
  /// Constructs a `Selector`.
  ///
  /// - Parameter keyPath: A key path to a store.
  /// - Parameter label: An optional `String` value used for debug logging.
  /// - Parameter isIncluded: An optional filter to indicate this `(State, Action)` pair could change an output. Pass no filter to indicate all action values could change an output.
  /// - Parameter dependencySelector: A parameter pack of `DependencySelector` values to compute dependencies. Pass no values to indicate no dependencies should be computed.
  /// - Parameter outputSelector: An `OutputSelector` value to compute an output.
  public init(
    _ keyPath: KeyPath<EnvironmentValues, Store>,
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<Store.State, each Dependency>,
    outputSelector: OutputSelector<Store.State, Output>
  ) {
    self._store = Environment(keyPath)
    self.listener = Listener(
      label: label,
      filter: isIncluded,
      dependencySelector: repeat each dependencySelector,
      outputSelector: outputSelector
    )
    self.id = nil
    self.label = label
    self.filter = isIncluded
    self.dependencySelector = (repeat each dependencySelector)
    self.outputSelector = outputSelector
  }
  
  /// The current value of the `OutputSelector`.
  ///
  /// When the output changes, SwiftUI updates the parts of the component hierarchy that depend on the output.
  public var wrappedValue: Output {
    self.listener.output
  }
}

extension Selector: @preconcurrency DynamicProperty {
  public mutating func update() {
    if let id = self.id {
      self.listener.update(
        id: id,
        label: self.label,
        filter: self.filter,
        dependencySelector: repeat each self.dependencySelector,
        outputSelector: self.outputSelector
      )
    } else {
      self.listener.update(
        label: self.label,
        filter: self.filter,
        dependencySelector: repeat each self.dependencySelector,
        outputSelector: self.outputSelector
      )
    }
    self.listener.listen(to: self.store)
  }
}
