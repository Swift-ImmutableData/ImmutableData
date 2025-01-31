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

public protocol PersistentSessionLocalStore: Sendable {
  func fetchLocalQuakesQuery() async throws -> Array<Quake>
  func didFetchRemoteQuakesMutation(
    inserted: Array<Quake>,
    updated: Array<Quake>,
    deleted: Array<Quake>
  ) async throws
  func deleteLocalQuakeMutation(quakeId: Quake.ID) async throws
  func deleteLocalQuakesMutation() async throws
}

public protocol PersistentSessionRemoteStore: Sendable {
  func fetchRemoteQuakesQuery(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) async throws -> Array<Quake>
}

final actor PersistentSession<LocalStore, RemoteStore> where LocalStore : PersistentSessionLocalStore, RemoteStore : PersistentSessionRemoteStore {
  private let localStore: LocalStore
  private let remoteStore: RemoteStore
  
  init(
    localStore: LocalStore,
    remoteStore: RemoteStore
  ) {
    self.localStore = localStore
    self.remoteStore = remoteStore
  }
}

extension PersistentSession {
  private func fetchLocalQuakesQuery(
    dispatcher: some ImmutableData.Dispatcher<QuakesState, QuakesAction>,
    selector: some ImmutableData.Selector<QuakesState>
  ) async throws {
    let quakes = try await {
      do {
        return try await self.localStore.fetchLocalQuakesQuery()
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .localStore(
                .didFetchQuakes(
                  result: .failure(
                    error: error.localizedDescription
                  )
                )
              )
            )
          )
        )
        throw error
      }
    }()
    try await dispatcher.dispatch(
      action: .data(
        .persistentSession(
          .localStore(
            .didFetchQuakes(
              result: .success(
                quakes: quakes
              )
            )
          )
        )
      )
    )
  }
}

extension PersistentSession {
  func fetchLocalQuakesQuery<Dispatcher, Selector>() -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher: ImmutableData.Dispatcher<QuakesState, QuakesAction>, Selector: ImmutableData.Selector<QuakesState> {
    { dispatcher, selector in
      try await self.fetchLocalQuakesQuery(
        dispatcher: dispatcher,
        selector: selector
      )
    }
  }
}

extension PersistentSession {
  private func didFetchRemoteQuakesMutation(
    dispatcher: some ImmutableData.Dispatcher<QuakesState, QuakesAction>,
    selector: some ImmutableData.Selector<QuakesState>,
    inserted: Array<Quake>,
    updated: Array<Quake>,
    deleted: Array<Quake>
  ) async throws {
    try await self.localStore.didFetchRemoteQuakesMutation(
      inserted: inserted,
      updated: updated,
      deleted: deleted
    )
  }
}

extension PersistentSession {
  func didFetchRemoteQuakesMutation<Dispatcher, Selector>(
    inserted: Array<Quake>,
    updated: Array<Quake>,
    deleted: Array<Quake>
  ) -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher: ImmutableData.Dispatcher<QuakesState, QuakesAction>, Selector: ImmutableData.Selector<QuakesState> {
    { dispatcher, selector in
      try await self.didFetchRemoteQuakesMutation(
        dispatcher: dispatcher,
        selector: selector,
        inserted: inserted,
        updated: updated,
        deleted: deleted
      )
    }
  }
}

extension PersistentSession {
  private func deleteLocalQuakeMutation(
    dispatcher: some ImmutableData.Dispatcher<QuakesState, QuakesAction>,
    selector: some ImmutableData.Selector<QuakesState>,
    quakeId: Quake.ID
  ) async throws {
    try await self.localStore.deleteLocalQuakeMutation(quakeId: quakeId)
  }
}

extension PersistentSession {
  func deleteLocalQuakeMutation<Dispatcher, Selector>(quakeId: Quake.ID) async throws -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher: ImmutableData.Dispatcher<QuakesState, QuakesAction>, Selector: ImmutableData.Selector<QuakesState> {
    { dispatcher, selector in
      try await self.deleteLocalQuakeMutation(
        dispatcher: dispatcher,
        selector: selector,
        quakeId: quakeId
      )
    }
  }
}

extension PersistentSession {
  private func deleteLocalQuakesMutation(
    dispatcher: some ImmutableData.Dispatcher<QuakesState, QuakesAction>,
    selector: some ImmutableData.Selector<QuakesState>
  ) async throws {
    try await self.localStore.deleteLocalQuakesMutation()
  }
}

extension PersistentSession {
  func deleteLocalQuakesMutation<Dispatcher, Selector>() -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher: ImmutableData.Dispatcher<QuakesState, QuakesAction>, Selector: ImmutableData.Selector<QuakesState> {
    { dispatcher, selector in
      try await self.deleteLocalQuakesMutation(
        dispatcher: dispatcher,
        selector: selector
      )
    }
  }
}

extension PersistentSession {
  private func fetchRemoteQuakesQuery(
    dispatcher: some ImmutableData.Dispatcher<QuakesState, QuakesAction>,
    selector: some ImmutableData.Selector<QuakesState>,
    range: QuakesAction.UI.QuakeList.RefreshQuakesRange
  ) async throws {
    let quakes = try await {
      do {
        return try await self.remoteStore.fetchRemoteQuakesQuery(range: range)
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .remoteStore(
                .didFetchQuakes(
                  result: .failure(
                    error: error.localizedDescription
                  )
                )
              ))
          )
        )
        throw error
      }
    }()
    try await dispatcher.dispatch(
      action: .data(
        .persistentSession(
          .remoteStore(
            .didFetchQuakes(
              result: .success(
                quakes: quakes
              )
            )
          )
        )
      )
    )
  }
}

extension PersistentSession {
  func fetchRemoteQuakesQuery<Dispatcher, Selector>(
    range: QuakesAction.UI.QuakeList.RefreshQuakesRange
  ) -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher: ImmutableData.Dispatcher<QuakesState, QuakesAction>, Selector: ImmutableData.Selector<QuakesState> {
    { dispatcher, selector in
      try await self.fetchRemoteQuakesQuery(
        dispatcher: dispatcher,
        selector: selector,
        range: range
      )
    }
  }
}
