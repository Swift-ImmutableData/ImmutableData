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

extension UserDefaults {
  fileprivate var isDebug: Bool {
    self.bool(forKey: "com.northbronson.QuakesData.Debug")
  }
}

@MainActor final public class Listener<LocalStore, RemoteStore> where LocalStore : PersistentSessionLocalStore, RemoteStore : PersistentSessionRemoteStore {
  private let session: PersistentSession<LocalStore, RemoteStore>
  
  private weak var store: AnyObject?
  private var task: Task<Void, any Error>?
  
  public init(
    localStore: LocalStore,
    remoteStore: RemoteStore
  ) {
    self.session = PersistentSession(
      localStore: localStore,
      remoteStore: remoteStore
    )
  }
  
  deinit {
    self.task?.cancel()
  }
}

extension Listener {
  public func listen(to store: some ImmutableData.Dispatcher<QuakesState, QuakesAction> & ImmutableData.Selector<QuakesState> & ImmutableData.Streamer<QuakesState, QuakesAction> & AnyObject) {
    if self.store !== store {
      self.store = store
      
      let stream = store.makeStream()
      
      self.task?.cancel()
      self.task = Task { [weak self] in
        for try await (oldState, action) in stream {
#if DEBUG
          if UserDefaults.standard.isDebug {
            print("[QuakesData][Listener] Old State: \(oldState)")
            print("[QuakesData][Listener] Action: \(action)")
            let newState = store.select({ state in state })
            print("[QuakesData][Listener] New State: \(newState)")
          }
#endif
          guard let self = self else { return }
          await self.onReceive(from: store, oldState: oldState, action: action)
        }
      }
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<QuakesState, QuakesAction> & ImmutableData.Selector<QuakesState>,
    oldState: QuakesState,
    action: QuakesAction
  ) async {
    switch action {
    case .ui(.quakeList(action: let action)):
      await self.onReceive(from: store, oldState: oldState, action: action)
    case .data(.persistentSession(action: let action)):
      await self.onReceive(from: store, oldState: oldState, action: action)
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<QuakesState, QuakesAction> & ImmutableData.Selector<QuakesState>,
    oldState: QuakesState,
    action: QuakesAction.UI.QuakeList
  ) async {
    switch action {
    case .onAppear:
      if oldState.quakes.status == nil,
         store.state.quakes.status == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.fetchLocalQuakesQuery()
          )
        } catch {
          print(error)
        }
      }
    case .onTapRefreshQuakesButton(range: let range):
      if oldState.quakes.status != .waiting,
         store.state.quakes.status == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.fetchRemoteQuakesQuery(range: range)
          )
        } catch {
          print(error)
        }
      }
    case .onTapDeleteSelectedQuakeButton(quakeId: let quakeId):
      do {
        try await store.dispatch(
          thunk: self.session.deleteLocalQuakeMutation(quakeId: quakeId)
        )
      } catch {
        print(error)
      }
    case .onTapDeleteAllQuakesButton:
      do {
        try await store.dispatch(
          thunk: self.session.deleteLocalQuakesMutation()
        )
      } catch {
        print(error)
      }
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<QuakesState, QuakesAction> & ImmutableData.Selector<QuakesState>,
    oldState: QuakesState,
    action: QuakesAction.Data.PersistentSession
  ) async {
    switch action {
    case .localStore(action: let action):
      await self.onReceive(from: store, oldState: oldState, action: action)
    case .remoteStore(action: let action):
      await self.onReceive(from: store, oldState: oldState, action: action)
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<QuakesState, QuakesAction> & ImmutableData.Selector<QuakesState>,
    oldState: QuakesState,
    action: QuakesAction.Data.PersistentSession.LocalStore
  ) async {
    switch action {
    default:
      break
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<QuakesState, QuakesAction> & ImmutableData.Selector<QuakesState>,
    oldState: QuakesState,
    action: QuakesAction.Data.PersistentSession.RemoteStore
  ) async {
    switch action {
    case .didFetchQuakes(result: let result):
      switch result {
      case .success(quakes: let quakes):
        var inserted = Array<Quake>()
        var updated = Array<Quake>()
        var deleted = Array<Quake>()
        for quake in quakes {
          if oldState.quakes.data[quake.id] == nil,
             store.state.quakes.data[quake.id] != nil {
            inserted.append(quake)
          }
          if let oldQuake = oldState.quakes.data[quake.id],
             let quake = store.state.quakes.data[quake.id],
             oldQuake != quake {
            updated.append(quake)
          }
          if oldState.quakes.data[quake.id] != nil,
             store.state.quakes.data[quake.id] == nil {
            deleted.append(quake)
          }
        }
        do {
          try await store.dispatch(
            thunk: self.session.didFetchRemoteQuakesMutation(
              inserted: inserted,
              updated: updated,
              deleted: deleted
            )
          )
        } catch {
          print(error)
        }
      default:
        break
      }
    }
  }
}
