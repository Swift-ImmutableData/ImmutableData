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
import Foundation
import Observation

//  https://github.com/swiftlang/swift-evolution/blob/main/proposals/0393-parameter-packs.md
//  https://github.com/swiftlang/swift-evolution/blob/main/proposals/0395-observability.md
//  https://github.com/swiftlang/swift-evolution/blob/main/proposals/0398-variadic-types.md
//  https://github.com/swiftlang/swift-evolution/blob/main/proposals/0408-pack-iteration.md

//  https://github.com/swiftlang/swift/issues/73690

extension UserDefaults {
  fileprivate var isDebug: Bool {
    self.bool(forKey: "com.northbronson.ImmutableUI.Debug")
  }
}

extension ImmutableData.Selector {
  @MainActor fileprivate func selectMany<each T>(_ select: repeat @escaping @Sendable (State) -> each T) -> (repeat each T) where repeat each T : Sendable {
    (repeat self.select(each select))
  }
}

@MainActor @Observable final fileprivate class Storage<Output> {
  var output: Output?
}

@MainActor final class AsyncListener<State, Action, each Dependency, Output> where State : Sendable, Action : Sendable, repeat each Dependency : Sendable, Output : Sendable {
  private let label: String?
  private let filter: (@Sendable (State, Action) -> Bool)?
  private let dependencySelector: (repeat DependencySelector<State, each Dependency>)
  private let outputSelector: OutputSelector<State, Output>
  
  private var oldDependency: (repeat each Dependency)?
  private var oldOutput: Output?
  private let storage = Storage<Output>()
  
  init(
    label: String? = nil,
    filter isIncluded: (@Sendable (State, Action) -> Bool)? = nil,
    dependencySelector: repeat DependencySelector<State, each Dependency>,
    outputSelector: OutputSelector<State, Output>
  ) {
    self.label = label
    self.filter = isIncluded
    self.dependencySelector = (repeat each dependencySelector)
    self.outputSelector = outputSelector
  }
}

extension AsyncListener {
  var output: Output {
    guard let output = self.storage.output else { fatalError("missing output") }
    return output
  }
}

extension AsyncListener {
  func update(with store: some ImmutableData.Selector<State>) {
#if DEBUG
    if let label = self.label,
       UserDefaults.standard.isDebug {
      print("[ImmutableUI][AsyncListener]: \(address(of: self)) Update: \(label)")
    }
#endif
    if self.hasDependency {
      if self.updateDependency(with: store) {
        self.updateOutput(with: store)
      }
    } else {
      self.updateOutput(with: store)
    }
  }
}

extension AsyncListener {
  func listen<S>(
    to stream: S,
    with store: some ImmutableData.Selector<State>
  ) async throws where S : AsyncSequence, S : Sendable, S.Element == (oldState: State, action: Action) {
    if let filter = self.filter {
      for try await _ in stream.filter(filter) {
        self.update(with: store)
      }
    } else {
      for try await _ in stream {
        self.update(with: store)
      }
    }
  }
}

extension AsyncListener {
  private var hasDependency: Bool {
    isEmpty(repeat each self.dependencySelector) == false
  }
}

extension AsyncListener {
  private func updateDependency(with store: some ImmutableData.Selector<State>) -> Bool {
#if DEBUG
    if let label = self.label,
       UserDefaults.standard.isDebug {
      print("[ImmutableUI][AsyncListener]: \(address(of: self)) Update Dependency: \(label)")
    }
#endif
    let dependency = store.selectMany(repeat (each self.dependencySelector).select)
    if let oldDependency = self.oldDependency {
      self.oldDependency = dependency
      return didChange(
        repeat (each self.dependencySelector).didChange,
        lhs: repeat each oldDependency,
        rhs: repeat each dependency
      )
    } else {
      self.oldDependency = dependency
      return true
    }
  }
}

extension AsyncListener {
  private func updateOutput(with store: some ImmutableData.Selector<State>) {
#if DEBUG
    if let label = self.label,
       UserDefaults.standard.isDebug {
      print("[ImmutableUI][AsyncListener]: \(address(of: self)) Update Output: \(label)")
    }
#endif
    let output = store.select(self.outputSelector.select)
    if let oldOutput = self.oldOutput {
      self.oldOutput = output
      if self.outputSelector.didChange(oldOutput, output) {
        self.storage.output = output
      }
    } else {
      self.oldOutput = output
      self.storage.output = output
    }
  }
}

fileprivate struct NotEmpty: Error {}

fileprivate func isEmpty<each Element>(_ element: repeat each Element) -> Bool {
  //  https://forums.swift.org/t/how-to-pass-nil-as-an-optional-parameter-pack/73119/6
  
  func _isEmpty<T>(_ t: T) throws {
    throw NotEmpty()
  }
  do {
    repeat try _isEmpty(each element)
  } catch {
    return false
  }
  return true
}

fileprivate struct DidChange: Error {}

fileprivate func didChange<each Element>(
  _ didChange: repeat @escaping @Sendable (each Element, each Element) -> Bool,
  lhs: repeat each Element,
  rhs: repeat each Element
) -> Bool {
  func _didChange<T>(_ didChange: (T, T) -> Bool, _ lhs: T, _ rhs: T) throws {
    if didChange(lhs, rhs) {
      throw DidChange()
    }
  }
  do {
    repeat try _didChange(each didChange, each lhs, each rhs)
  } catch {
    return true
  }
  return false
}

fileprivate func address(of x: AnyObject) -> String {
  //  https://github.com/apple/swift/blob/swift-5.10.1-RELEASE/stdlib/public/core/Runtime.swift#L516-L528
  //  https://github.com/apple/swift/blob/swift-5.10.1-RELEASE/test/Concurrency/voucher_propagation.swift#L78-L81
  
  var result = String(
    unsafeBitCast(x, to: UInt.self),
    radix: 16
  )
  for _ in 0..<(2 * MemoryLayout<UnsafeRawPointer>.size - result.utf16.count) {
    result = "0" + result
  }
  return "0x" + result
}
