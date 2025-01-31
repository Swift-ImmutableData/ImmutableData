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
import Collections
import Foundation
import ImmutableData
import QuakesData
import Testing

final fileprivate class Error : Swift.Error {
  
}

extension PersistentSessionRemoteStore {
  fileprivate func fetchRemoteQuakesQuery(range: QuakesData.QuakesAction.UI.QuakeList.RefreshQuakesRange) throws -> Array<QuakesData.Quake> {
    fatalError()
  }
}

final fileprivate class RemoteStoreTestDouble : PersistentSessionRemoteStore {
  
}

final fileprivate class FetchRemoteQuakesQueryRemoteStoreTestDouble : @unchecked Sendable, PersistentSessionRemoteStore {
  var range: QuakesData.QuakesAction.UI.QuakeList.RefreshQuakesRange?
  let quakes: Array<Quake>?
  let error = Error()
  
  init(quakes: Array<Quake>? = nil) {
    self.quakes = quakes
  }
  
  func fetchRemoteQuakesQuery(range: QuakesData.QuakesAction.UI.QuakeList.RefreshQuakesRange) throws -> Array<QuakesData.Quake> {
    self.range = range
    guard let quakes = self.quakes else {
      throw self.error
    }
    return quakes
  }
}

extension PersistentSessionLocalStore {
  fileprivate func fetchLocalQuakesQuery() throws -> Array<QuakesData.Quake> {
    fatalError()
  }
  fileprivate func didFetchRemoteQuakesMutation(
    inserted: Array<Quake>,
    updated: Array<Quake>,
    deleted: Array<Quake>
  ) throws {
    fatalError()
  }
  fileprivate func deleteLocalQuakeMutation(quakeId: String) throws {
    fatalError()
  }
  fileprivate func deleteLocalQuakesMutation() throws {
    fatalError()
  }
}

final fileprivate class LocalStoreTestDouble : @unchecked Sendable, PersistentSessionLocalStore {
  
}

final fileprivate class FetchLocalQuakesQueryLocalStoreTestDouble : @unchecked Sendable, PersistentSessionLocalStore {
  let quakes: Array<Quake>?
  let error = Error()
  
  init(quakes: Array<Quake>? = nil) {
    self.quakes = quakes
  }
  
  func fetchLocalQuakesQuery() throws -> Array<QuakesData.Quake> {
    guard let quakes = self.quakes else {
      throw self.error
    }
    return quakes
  }
}

final fileprivate class DeleteLocalQuakeMutationLocalStoreTestDouble : @unchecked Sendable, PersistentSessionLocalStore {
  var quakeId: String?
  let error: Error?
  
  init(error: Error? = nil) {
    self.error = error
  }
  
  func deleteLocalQuakeMutation(quakeId: String) throws {
    self.quakeId = quakeId
    if let error = self.error {
      throw error
    }
  }
}

final fileprivate class DeleteLocalQuakesMutationLocalStoreTestDouble : @unchecked Sendable, PersistentSessionLocalStore {
  var didDelete = false
  let error: Error?
  
  init(error: Error? = nil) {
    self.error = error
  }
  
  func deleteLocalQuakesMutation() throws {
    self.didDelete = true
    if let error = self.error {
      throw error
    }
  }
}

final fileprivate class DidFetchRemoteQuakesMutationLocalStoreTestDouble : @unchecked Sendable, PersistentSessionLocalStore {
  var inserted: Array<QuakesData.Quake>?
  var updated: Array<QuakesData.Quake>?
  var deleted: Array<QuakesData.Quake>?
  let error: Error?
  
  init(error: Error? = nil) {
    self.error = error
  }
  
  func didFetchRemoteQuakesMutation(
    inserted: Array<Quake>,
    updated: Array<Quake>,
    deleted: Array<Quake>
  ) throws {
    self.inserted = inserted
    self.updated = updated
    self.deleted = deleted
    if let error = self.error {
      throw error
    }
  }
}

@MainActor final fileprivate class StoreTestDouble : Sendable {
  typealias State = QuakesData.QuakesState
  typealias Action = QuakesData.QuakesAction
  
  let sequence = AsyncSequenceTestDouble<(oldState: State, action: Action)>()
  
  var parameterAction = Array<Action>()
  let returnState: State
  
  init(returnState: State) {
    self.returnState = returnState
  }
}

extension StoreTestDouble : ImmutableData.Dispatcher {
  func dispatch(action: Action) throws {
    self.parameterAction.append(action)
  }
  
  func dispatch(thunk: @Sendable (StoreTestDouble, StoreTestDouble) throws -> Void) rethrows {
    try thunk(self, self)
  }
  
  func dispatch(thunk: @Sendable (StoreTestDouble, StoreTestDouble) async throws -> Void) async rethrows {
    try await thunk(self, self)
  }
}

extension StoreTestDouble : ImmutableData.Selector {
  func select<T>(_ selector: @Sendable (State) -> T) -> T where T : Sendable {
    return selector(self.returnState)
  }
}

extension StoreTestDouble : ImmutableData.Streamer {
  func makeStream() -> AsyncSequenceTestDouble<(oldState: State, action: Action)>{
    self.sequence
  }
}

@Suite final actor ListenerTests {
  
}

extension ListenerTests {
  private static let state = QuakesState(
    quakes: QuakesState.Quakes(
      data: TreeDictionary(
        Quake(
          quakeId: "1",
          magnitude: 0.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "2",
          magnitude: 1.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "3",
          magnitude: 2.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "4",
          magnitude: 3.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "5",
          magnitude: 4.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "6",
          magnitude: 5.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "7",
          magnitude: 6.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "8",
          magnitude: 7.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        )
      )
    )
  )
}

extension ListenerTests {
  @Test func uiListOnAppearSuccess() async throws {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = FetchLocalQuakesQueryLocalStoreTestDouble(quakes: Array(Self.state.quakes.data.values))
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState(
        quakes: QuakesState.Quakes(status: .waiting)
      )
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onAppear))))
    
    #expect(await store.parameterAction.count == 1)
    
    let quakes = try await #require(
      {
        if case .data(
          .persistentSession(
            .localStore(
              .didFetchQuakes(
                result: .success(
                  quakes: let quakes
                )
              )
            )
          )
        ) = await store.parameterAction[0] {
          return quakes
        }
        return nil
      }()
    )
    #expect(quakes == localStore.quakes)
  }
}

extension ListenerTests {
  @Test func uiListOnAppearFailure() async throws {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = FetchLocalQuakesQueryLocalStoreTestDouble()
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState(
        quakes: QuakesState.Quakes(status: .waiting)
      )
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onAppear))))
    
    #expect(await store.parameterAction.count == 1)
    
    let error = try await #require(
      {
        if case .data(
          .persistentSession(
            .localStore(
              .didFetchQuakes(
                result: .failure(
                  error: let error
                )
              )
            )
          )
        ) = await store.parameterAction[0] {
          return error
        }
        return nil
      }()
    )
    #expect(error == localStore.error.localizedDescription)
  }
}

extension ListenerTests {
  @Test(
    arguments: [
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allHour,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allDay,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allWeek,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allMonth,
    ]
  ) func uiListOnTapRefreshQuakesButtonSuccess(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) async throws {
    let remoteStore = FetchRemoteQuakesQueryRemoteStoreTestDouble(quakes: Array(Self.state.quakes.data.values))
    let localStore = LocalStoreTestDouble()
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState(
        quakes: QuakesState.Quakes(status: .waiting)
      )
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onTapRefreshQuakesButton(range: range)))))
    
    #expect(remoteStore.range == range)
    
    #expect(await store.parameterAction.count == 1)
    
    let quakes = try await #require(
      {
        if case .data(
          .persistentSession(
            .remoteStore(
              .didFetchQuakes(
                result: .success(
                  quakes: let quakes
                )
              )
            )
          )
        ) = await store.parameterAction[0] {
          return quakes
        }
        return nil
      }()
    )
    #expect(quakes == remoteStore.quakes)
  }
}

extension ListenerTests {
  @Test(
    arguments: [
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allHour,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allDay,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allWeek,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allMonth,
    ]
  ) func uiListOnTapRefreshQuakesButtonFailure(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) async throws {
    let remoteStore = FetchRemoteQuakesQueryRemoteStoreTestDouble()
    let localStore = LocalStoreTestDouble()
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState(
        quakes: QuakesState.Quakes(status: .waiting)
      )
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onTapRefreshQuakesButton(range: range)))))
    
    #expect(remoteStore.range == range)
    
    #expect(await store.parameterAction.count == 1)
    
    let error = try await #require(
      {
        if case .data(
          .persistentSession(
            .remoteStore(
              .didFetchQuakes(
                result: .failure(
                  error: let error
                )
              )
            )
          )
        ) = await store.parameterAction[0] {
          return error
        }
        return nil
      }()
    )
    #expect(error == remoteStore.error.localizedDescription)
  }
}

extension ListenerTests {
  @Test func uiListOnTapDeleteSelectedQuakeButtonSuccess() async throws {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = DeleteLocalQuakeMutationLocalStoreTestDouble()
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState()
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onTapDeleteSelectedQuakeButton(quakeId: "quakeId")))))
    
    #expect(localStore.quakeId ==  "quakeId")
    
    #expect(await store.parameterAction.count == 0)
  }
}

extension ListenerTests {
  @Test func uiListOnTapDeleteSelectedQuakeButtonFailure() async throws {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = DeleteLocalQuakeMutationLocalStoreTestDouble(error: Error())
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState()
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onTapDeleteSelectedQuakeButton(quakeId: "quakeId")))))
    
    #expect(localStore.quakeId ==  "quakeId")
    
    #expect(await store.parameterAction.count == 0)
  }
}

extension ListenerTests {
  @Test func uiListOnTapDeleteAllQuakesButtonSuccess() async throws {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = DeleteLocalQuakesMutationLocalStoreTestDouble()
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState()
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onTapDeleteAllQuakesButton))))
    
    #expect(localStore.didDelete)
    
    #expect(await store.parameterAction.count == 0)
  }
}

extension ListenerTests {
  @Test func uiListOnTapDeleteAllQuakesButtonFailure() async throws {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = DeleteLocalQuakesMutationLocalStoreTestDouble(error: Error())
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: QuakesState()
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: QuakesState(), action: .ui(.quakeList(.onTapDeleteAllQuakesButton))))
    
    #expect(localStore.didDelete)
    
    #expect(await store.parameterAction.count == 0)
  }
}

extension ListenerTests {
  @Test func dataPersistentSessionRemoteStoreDidFetchQuakesSuccess() async throws {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = DidFetchRemoteQuakesMutationLocalStoreTestDouble()
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(
      returnState: {
        var state = Self.state
        state.quakes.data["1"] = Quake(
          quakeId: "1",
          magnitude: 1.0,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 2.0),
          name: "name",
          longitude: -125,
          latitude: 35
        )
        state.quakes.data["2"] = nil
        state.quakes.data["quakeId"] = Quake(
          quakeId: "quakeId",
          magnitude: 1.0,
          time: Date(timeIntervalSince1970: 2.0),
          updated: Date(timeIntervalSince1970: 2.0),
          name: "name",
          longitude: -125,
          latitude: 35
        )
        return state
      }()
    )
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(
      returning: (
        oldState: Self.state,
        action: .data(
          .persistentSession(
            .remoteStore(
              .didFetchQuakes(
                result: .success(
                  quakes: {
                    var data = Self.state.quakes.data
                    data["1"] = Quake(
                      quakeId: "1",
                      magnitude: 1.0,
                      time: Date(timeIntervalSince1970: 1.0),
                      updated: Date(timeIntervalSince1970: 2.0),
                      name: "name",
                      longitude: -125,
                      latitude: 35
                    )
                    data["2"] = Quake(
                      quakeId: "2",
                      magnitude: 0.0,
                      time: Date(timeIntervalSince1970: 1.0),
                      updated: Date(timeIntervalSince1970: 1.0),
                      name: "West of California",
                      longitude: -125,
                      latitude: 35
                    )
                    data["quakeId"] = Quake(
                      quakeId: "quakeId",
                      magnitude: 1.0,
                      time: Date(timeIntervalSince1970: 2.0),
                      updated: Date(timeIntervalSince1970: 2.0),
                      name: "name",
                      longitude: -125,
                      latitude: 35
                    )
                    return Array(data.values)
                  }()
                )
              )
            )
          )
        )
      )
    )
    
    let inserted = try #require(localStore.inserted)
    #expect(inserted == [
      Quake(
        quakeId: "quakeId",
        magnitude: 1.0,
        time: Date(timeIntervalSince1970: 2.0),
        updated: Date(timeIntervalSince1970: 2.0),
        name: "name",
        longitude: -125,
        latitude: 35
      )
    ])
    
    let updated = try #require(localStore.updated)
    #expect(updated == [
      Quake(
        quakeId: "1",
        magnitude: 1.0,
        time: Date(timeIntervalSince1970: 1.0),
        updated: Date(timeIntervalSince1970: 2.0),
        name: "name",
        longitude: -125,
        latitude: 35
      )
    ])
    
    let deleted = try #require(localStore.deleted)
    #expect(deleted == [
      Quake(
        quakeId: "2",
        magnitude: 0.0,
        time: Date(timeIntervalSince1970: 1.0),
        updated: Date(timeIntervalSince1970: 1.0),
        name: "West of California",
        longitude: -125,
        latitude: 35
      )
    ])
    
    #expect(await store.parameterAction.count == 0)
  }
}

extension ListenerTests {
  @Test(
    arguments: [
      (
        QuakesState(),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState()
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .empty)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState()
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .waiting)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState()
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .success)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState()
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error"))),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState()
      ),
      (
        QuakesState(),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .empty))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .empty)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .empty))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .waiting)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .empty))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .success)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .empty))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error"))),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .empty))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .empty)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .waiting))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .waiting)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .waiting))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .success)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .waiting))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error"))),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .waiting))
      ),
      (
        QuakesState(),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .success))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .empty)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .success))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .waiting)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .success))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .success)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .success))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error"))),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .success))
      ),
      (
        QuakesState(),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error")))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .empty)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error")))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .waiting)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error")))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .success)),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error")))
      ),
      (
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error"))),
        QuakesAction.ui(.quakeList(.onAppear)),
        QuakesState(quakes: QuakesState.Quakes(status: .failure(error: "error")))
      ),
      (
        QuakesState(),
        QuakesAction.data(.persistentSession(.localStore(.didFetchQuakes(result: .success(quakes: []))))),
        QuakesState()
      ),
      (
        QuakesState(),
        QuakesAction.data(.persistentSession(.localStore(.didFetchQuakes(result: .failure(error: "error"))))),
        QuakesState()
      ),
      (
        QuakesState(),
        QuakesAction.data(.persistentSession(.remoteStore(.didFetchQuakes(result: .failure(error: "error"))))),
        QuakesState()
      ),
    ]
  ) func doesNothing(
    oldState: QuakesState,
    action: QuakesAction,
    newState: QuakesState
  ) async {
    let remoteStore = RemoteStoreTestDouble()
    let localStore = LocalStoreTestDouble()
    
    let listener = await Listener(
      localStore: localStore,
      remoteStore: remoteStore
    )
    let store = await StoreTestDouble(returnState: newState)
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: oldState, action: action))
    
    #expect(await store.parameterAction.isEmpty)
  }
}
