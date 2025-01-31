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
import Testing

//  https://github.com/swiftlang/swift/issues/74882

final fileprivate class Error : Swift.Error {
  
}

final fileprivate class StateTestDouble : Sendable {
  
}

final fileprivate class ActionTestDouble : Sendable {
  
}

final fileprivate class ReducerTestDouble : @unchecked Sendable {
  var parameterState: StateTestDouble?
  var parameterAction: ActionTestDouble?
  var returnError: Error?
  let returnState = StateTestDouble()
}

extension ReducerTestDouble {
  @Sendable func reduce(
    state: StateTestDouble,
    action: ActionTestDouble
  ) throws -> StateTestDouble {
    self.parameterState = state
    self.parameterAction = action
    if let returnError = self.returnError {
      throw returnError
    }
    return self.returnState
  }
}

final fileprivate class ThunkTestDouble : @unchecked Sendable {
  var parameterDispatcher: Store<StateTestDouble, ActionTestDouble>?
  var parameterSelector: Store<StateTestDouble, ActionTestDouble>?
  var returnError: Error?
}

extension ThunkTestDouble {
  @Sendable func thunk(
    dispatcher: Store<StateTestDouble, ActionTestDouble>,
    selector: Store<StateTestDouble, ActionTestDouble>
  ) throws {
    self.parameterDispatcher = dispatcher
    self.parameterSelector = selector
    if let returnError = self.returnError {
      throw returnError
    }
  }
}

extension ThunkTestDouble {
  @Sendable func asyncThunk(
    dispatcher: Store<StateTestDouble, ActionTestDouble>,
    selector: Store<StateTestDouble, ActionTestDouble>
  ) async throws {
    self.parameterDispatcher = dispatcher
    self.parameterSelector = selector
    if let returnError = self.returnError {
      throw returnError
    }
  }
}

@Suite final actor StoreTests : Sendable {
  private let state = StateTestDouble()
  private let action = ActionTestDouble()
  private let reducer = ReducerTestDouble()
  private let thunk = ThunkTestDouble()
}

extension StoreTests {
  @Test func select() async {
    let store = await Store(
      initialState: self.state,
      reducer: self.reducer.reduce
    )
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
  }
}

extension StoreTests {
  @Test func dispatchActionThrowsError() async throws {
    self.reducer.returnError = Error()
    
    let store = await Store(
      initialState: self.state,
      reducer: self.reducer.reduce
    )
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    do {
      try await store.dispatch(action: self.action)
      #expect(false)
    } catch {
      let error = try #require(error as? Error)
      #expect(error === self.reducer.returnError)
    }
    
    #expect(self.reducer.parameterState === self.state)
    #expect(self.reducer.parameterAction === self.action)
    
    #expect(await store.state === self.state)
  }
}

extension StoreTests {
  @Test func dispatchActionNoThrow() async throws {
    let store = await Store(
      initialState: self.state,
      reducer: self.reducer.reduce
    )
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    try await store.dispatch(action: self.action)
    
    #expect(self.reducer.parameterState === self.state)
    #expect(self.reducer.parameterAction === self.action)
    
    #expect(await store.state === self.reducer.returnState)
  }
}

extension StoreTests {
  @Test func dispatchThunkThrowsError() async throws {
    self.thunk.returnError = Error()
    
    let store = await Store(
      initialState: self.state,
      reducer: self.reducer.reduce
    )
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    do {
      try await store.dispatch(thunk: self.thunk.thunk)
      #expect(false)
    } catch {
      let error = try #require(error as? Error)
      #expect(error === self.thunk.returnError)
    }
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    let parameterDispatcher = try #require(self.thunk.parameterDispatcher)
    #expect(parameterDispatcher === store)
    
    let parameterSelector = try #require(self.thunk.parameterSelector)
    #expect(parameterSelector === store)
  }
}

extension StoreTests {
  @Test func dispatchThunkNoThrow() async throws {
    let store = await Store(
      initialState: self.state,
      reducer: self.reducer.reduce
    )
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    try await store.dispatch(thunk: self.thunk.thunk)
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    let parameterDispatcher = try #require(self.thunk.parameterDispatcher)
    #expect(parameterDispatcher === store)
    
    let parameterSelector = try #require(self.thunk.parameterSelector)
    #expect(parameterSelector === store)
  }
}

extension StoreTests {
  @Test func dispatchAsyncThunkThrowsError() async throws {
    self.thunk.returnError = Error()
    
    let store = await Store(
      initialState: self.state,
      reducer: self.reducer.reduce
    )
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    do {
      try await store.dispatch(thunk: self.thunk.asyncThunk)
      #expect(false)
    } catch {
      let error = try #require(error as? Error)
      #expect(error === self.thunk.returnError)
    }
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    let parameterDispatcher = try #require(self.thunk.parameterDispatcher)
    #expect(parameterDispatcher === store)
    
    let parameterSelector = try #require(self.thunk.parameterSelector)
    #expect(parameterSelector === store)
  }
}

extension StoreTests {
  @Test func dispatchAsyncThunkNoThrow() async throws {
    let store = await Store(
      initialState: self.state,
      reducer: self.reducer.reduce
    )
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    try await store.dispatch(thunk: self.thunk.asyncThunk)
    
    #expect(self.reducer.parameterState == nil)
    #expect(self.reducer.parameterAction == nil)
    
    #expect(await store.state === self.state)
    
    let parameterDispatcher = try #require(self.thunk.parameterDispatcher)
    #expect(parameterDispatcher === store)
    
    let parameterSelector = try #require(self.thunk.parameterSelector)
    #expect(parameterSelector === store)
  }
}

extension StoreTests {
  @Test func streamCancel() async throws {
    try await withThrowingTaskGroup(of: Void.self) { @Sendable group in
      let store = await Store(
        initialState: self.state,
        reducer: self.reducer.reduce
      )
      
      #expect(self.reducer.parameterState == nil)
      #expect(self.reducer.parameterAction == nil)
      
      #expect(await store.state === self.state)
      
      let stream = await store.makeStream()
      
      group.addTask { [state, action, reducer] in
        await Testing.confirmation(expectedCount: 1) { finished in
          await Testing.confirmation(expectedCount: 1) { iterated in
            var array = [reducer.returnState, state]
            for await value in stream {
              #expect(value.oldState === array.removeLast())
              #expect(value.action === action)
              iterated()
            }
            finished()
          }
        }
      }
      
      try await store.dispatch(action: self.action)
      
      #expect(self.reducer.parameterState === self.state)
      #expect(self.reducer.parameterAction === self.action)
      
      #expect(await store.state === self.reducer.returnState)
      
      group.cancelAll()
      try await group.waitForAll()
      
      try await store.dispatch(action: self.action)
      
      #expect(self.reducer.parameterState === self.reducer.returnState)
      #expect(self.reducer.parameterAction === self.action)
      
      #expect(await store.state === self.reducer.returnState)
    }
  }
}

extension StoreTests {
  @Test func streamFinish() async throws {
    try await withThrowingTaskGroup(of: Void.self) { @Sendable group in
      let store = await Store(
        initialState: self.state,
        reducer: self.reducer.reduce
      )
      
      #expect(self.reducer.parameterState == nil)
      #expect(self.reducer.parameterAction == nil)
      
      #expect(await store.state === self.state)
      
      let stream = await store.makeStream()
      
      group.addTask { [state, action, reducer] in
        await Testing.confirmation(expectedCount: 1) { finished in
          await Testing.confirmation(expectedCount: 2) { iterated in
            var array = [reducer.returnState, state]
            for await value in stream {
              #expect(value.oldState === array.removeLast())
              #expect(value.action === action)
              iterated()
            }
            finished()
          }
        }
      }
      
      try await store.dispatch(action: self.action)
      
      #expect(self.reducer.parameterState === self.state)
      #expect(self.reducer.parameterAction === self.action)
      
      #expect(await store.state === self.reducer.returnState)
      
      try await store.dispatch(action: self.action)
      
      #expect(self.reducer.parameterState === self.reducer.returnState)
      #expect(self.reducer.parameterAction === self.action)
      
      #expect(await store.state === self.reducer.returnState)
    }
  }
}
