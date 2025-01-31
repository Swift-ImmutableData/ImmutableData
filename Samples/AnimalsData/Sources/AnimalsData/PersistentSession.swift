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

public protocol PersistentSessionPersistentStore: Sendable {
  func fetchAnimalsQuery() async throws -> Array<Animal>
  func addAnimalMutation(
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal
  func updateAnimalMutation(
    animalId: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal
  func deleteAnimalMutation(animalId: String) async throws -> Animal
  func fetchCategoriesQuery() async throws -> Array<Category>
  func reloadSampleDataMutation() async throws -> (
    animals: Array<Animal>,
    categories: Array<Category>
  )
}

final actor PersistentSession<PersistentStore> where PersistentStore : PersistentSessionPersistentStore {
  private let store: PersistentStore

  init(store: PersistentStore) {
    self.store = store
  }
}

extension PersistentSession {
  func fetchAnimalsQuery<Dispatcher, Selector>() -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher : ImmutableData.Dispatcher<AnimalsState, AnimalsAction>, Selector : ImmutableData.Selector<AnimalsState> {
    { dispatcher, selector in
      try await self.fetchAnimalsQuery(
        dispatcher: dispatcher,
        selector: selector
      )
    }
  }
}

extension PersistentSession {
  private func fetchAnimalsQuery(
    dispatcher: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction>,
    selector: some ImmutableData.Selector<AnimalsState>
  ) async throws {
    let animals = try await {
      do {
        return try await self.store.fetchAnimalsQuery()
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .didFetchAnimals(
                result: .failure(
                  error: error.localizedDescription
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
          .didFetchAnimals(
            result: .success(
              animals: animals
            )
          )
        )
      )
    )
  }
}

extension PersistentSession {
  func addAnimalMutation<Dispatcher, Selector>(
    id: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher : ImmutableData.Dispatcher<AnimalsState, AnimalsAction>, Selector : ImmutableData.Selector<AnimalsState> {
    { dispatcher, selector in
      try await self.addAnimalMutation(
        dispatcher: dispatcher,
        selector: selector,
        id: id,
        name: name,
        diet: diet,
        categoryId: categoryId
      )
    }
  }
}

extension PersistentSession {
  private func addAnimalMutation(
    dispatcher: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction>,
    selector: some ImmutableData.Selector<AnimalsState>,
    id: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws {
    let animal = try await {
      do {
        return try await self.store.addAnimalMutation(
          name: name,
          diet: diet,
          categoryId: categoryId
        )
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .didAddAnimal(
                id: id,
                result: .failure(
                  error: error.localizedDescription
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
          .didAddAnimal(
            id: id,
            result: .success(
              animal: animal
            )
          )
        )
      )
    )
  }
}

extension PersistentSession {
  func updateAnimalMutation<Dispatcher, Selector>(
    animalId: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher : ImmutableData.Dispatcher<AnimalsState, AnimalsAction>, Selector : ImmutableData.Selector<AnimalsState> {
    { dispatcher, selector in
      try await self.updateAnimalMutation(
        dispatcher: dispatcher,
        selector: selector,
        animalId: animalId,
        name: name,
        diet: diet,
        categoryId: categoryId
      )
    }
  }
}

extension PersistentSession {
  private func updateAnimalMutation(
    dispatcher: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction>,
    selector: some ImmutableData.Selector<AnimalsState>,
    animalId: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws {
    let animal = try await {
      do {
        return try await self.store.updateAnimalMutation(
          animalId: animalId,
          name: name,
          diet: diet,
          categoryId: categoryId
        )
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .didUpdateAnimal(
                animalId: animalId,
                result: .failure(
                  error: error.localizedDescription
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
          .didUpdateAnimal(
            animalId: animalId,
            result: .success(
              animal: animal
            )
          )
        )
      )
    )
  }
}

extension PersistentSession {
  func deleteAnimalMutation<Dispatcher, Selector>(
    animalId: String
  ) -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher : ImmutableData.Dispatcher<AnimalsState, AnimalsAction>, Selector : ImmutableData.Selector<AnimalsState> {
    { dispatcher, selector in
      try await self.deleteAnimalMutation(
        dispatcher: dispatcher,
        selector: selector,
        animalId: animalId
      )
    }
  }
}

extension PersistentSession {
  private func deleteAnimalMutation(
    dispatcher: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction>,
    selector: some ImmutableData.Selector<AnimalsState>,
    animalId: String
  ) async throws {
    let animal = try await {
      do {
        return try await self.store.deleteAnimalMutation(
          animalId: animalId
        )
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .didDeleteAnimal(
                animalId: animalId,
                result: .failure(
                  error: error.localizedDescription
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
          .didDeleteAnimal(
            animalId: animalId,
            result: .success(
              animal: animal
            )
          )
        )
      )
    )
  }
}

extension PersistentSession {
  func fetchCategoriesQuery<Dispatcher, Selector>() -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher : ImmutableData.Dispatcher<AnimalsState, AnimalsAction>, Selector : ImmutableData.Selector<AnimalsState> {
    { dispatcher, selector in
      try await self.fetchCategoriesQuery(
        dispatcher: dispatcher,
        selector: selector
      )
    }
  }
}

extension PersistentSession {
  private func fetchCategoriesQuery(
    dispatcher: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction>,
    selector: some ImmutableData.Selector<AnimalsState>
  ) async throws {
    let categories = try await {
      do {
        return try await self.store.fetchCategoriesQuery()
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .didFetchCategories(
                result: .failure(
                  error: error.localizedDescription
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
          .didFetchCategories(
            result: .success(
              categories: categories
            )
          )
        )
      )
    )
  }
}

extension PersistentSession {
  func reloadSampleDataMutation<Dispatcher, Selector>() -> @Sendable (
    Dispatcher,
    Selector
  ) async throws -> Void where Dispatcher : ImmutableData.Dispatcher<AnimalsState, AnimalsAction>, Selector : ImmutableData.Selector<AnimalsState> {
    { dispatcher, selector in
      try await self.reloadSampleDataMutation(
        dispatcher: dispatcher,
        selector: selector
      )
    }
  }
}

extension PersistentSession {
  private func reloadSampleDataMutation(
    dispatcher: some ImmutableData.Dispatcher<AnimalsState, AnimalsAction>,
    selector: some ImmutableData.Selector<AnimalsState>
  ) async throws {
    let (animals, categories) = try await {
      do {
        return try await self.store.reloadSampleDataMutation()
      } catch {
        try await dispatcher.dispatch(
          action: .data(
            .persistentSession(
              .didReloadSampleData(
                result: .failure(
                  error: error.localizedDescription
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
          .didReloadSampleData(
            result: .success(
              animals: animals,
              categories: categories
            )
          )
        )
      )
    )
  }
}
