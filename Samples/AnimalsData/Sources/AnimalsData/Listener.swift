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

import Foundation
import ImmutableData

extension UserDefaults {
  fileprivate var isDebug: Bool {
    self.bool(forKey: "com.northbronson.AnimalsData.Debug")
  }
}

@MainActor final public class Listener<PersistentStore> where PersistentStore : PersistentSessionPersistentStore {
  private let session: PersistentSession<PersistentStore>
  
  private weak var store: AnyObject?
  private var task: Task<Void, any Error>?
  
  public init(store: PersistentStore) {
    self.session = PersistentSession(store: store)
  }
  
  deinit {
    self.task?.cancel()
  }
}

extension Listener {
  public func listen(to store: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction> & ImmutableData.Selector<AnimalsState> & ImmutableData.Streamer<AnimalsState, AnimalsAction> & AnyObject) {
    if self.store !== store {
      self.store = store
      
      let stream = store.makeStream()
      
      self.task?.cancel()
      self.task = Task { [weak self] in
        for try await (oldState, action) in stream {
#if DEBUG
          if UserDefaults.standard.isDebug {
            print("[AnimalsData][Listener] Old State: \(oldState)")
            print("[AnimalsData][Listener] Action: \(action)")
            let newState = store.select({ state in state })
            print("[AnimalsData][Listener] New State: \(newState)")
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
    from store: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction> & ImmutableData.Selector<AnimalsState>,
    oldState: AnimalsState,
    action: AnimalsAction
  ) async {
    switch action {
    case .ui(action: let action):
      await self.onReceive(from: store, oldState: oldState, action: action)
    default:
      break
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction> & ImmutableData.Selector<AnimalsState>,
    oldState: AnimalsState,
    action: AnimalsAction.UI
  ) async {
    switch action {
    case .categoryList(action: let action):
      await self.onReceive(from: store, oldState: oldState, action: action)
    case .animalList(action: let action):
      await self.onReceive(from: store, oldState: oldState, action: action)
    case .animalDetail(action: let action):
      await self.onReceive(from: store, oldState: oldState, action: action)
    case .animalEditor(action: let action):
      await self.onReceive(from: store, oldState: oldState, action: action)
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction> & ImmutableData.Selector<AnimalsState>,
    oldState: AnimalsState,
    action: AnimalsAction.UI.CategoryList
  ) async {
    let newState = store.select({ state in state })
    switch action {
    case .onAppear:
      if oldState.categories.status == nil,
         newState.categories.status == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.fetchCategoriesQuery()
          )
        } catch {
          print(error)
        }
      }
    case .onTapReloadSampleDataButton:
      if oldState.categories.status != .waiting,
         newState.categories.status == .waiting,
         oldState.animals.status != .waiting,
         newState.animals.status == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.reloadSampleDataMutation()
          )
        } catch {
          print(error)
        }
      }
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction> & ImmutableData.Selector<AnimalsState>,
    oldState: AnimalsState,
    action: AnimalsAction.UI.AnimalList
  ) async {
    let newState = store.select({ state in state })
    switch action {
    case .onAppear:
      if oldState.animals.status == nil,
         newState.animals.status == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.fetchAnimalsQuery()
          )
        } catch {
          print(error)
        }
      }
    case .onTapDeleteSelectedAnimalButton(animalId: let animalId):
      if oldState.animals.queue[animalId] != .waiting,
         newState.animals.queue[animalId] == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.deleteAnimalMutation(animalId: animalId)
          )
        } catch {
          print(error)
        }
      }
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction> & ImmutableData.Selector<AnimalsState>,
    oldState: AnimalsState,
    action: AnimalsAction.UI.AnimalDetail
  ) async {
    let newState = store.select({ state in state })
    switch action {
    case .onTapDeleteSelectedAnimalButton(animalId: let animalId):
      if oldState.animals.queue[animalId] != .waiting,
         newState.animals.queue[animalId] == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.deleteAnimalMutation(animalId: animalId)
          )
        } catch {
          print(error)
        }
      }
    }
  }
}

extension Listener {
  private func onReceive(
    from store: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction> & ImmutableData.Selector<AnimalsState>,
    oldState: AnimalsState,
    action: AnimalsAction.UI.AnimalEditor
  ) async {
    let newState = store.select({ state in state })
    switch action {
    case .onTapAddAnimalButton(id: let id, name: let name, diet: let diet, categoryId: let categoryId):
      if oldState.animals.queue[id] != .waiting,
         newState.animals.queue[id] == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.addAnimalMutation(id: id, name: name, diet: diet, categoryId: categoryId)
          )
        } catch {
          print(error)
        }
      }
    case .onTapUpdateAnimalButton(animalId: let animalId, name: let name, diet: let diet, categoryId: let categoryId):
      if oldState.animals.queue[animalId] != .waiting,
         newState.animals.queue[animalId] == .waiting {
        do {
          try await store.dispatch(
            thunk: self.session.updateAnimalMutation(animalId: animalId, name: name, diet: diet, categoryId: categoryId)
          )
        } catch {
          print(error)
        }
      }
    }
  }
}
