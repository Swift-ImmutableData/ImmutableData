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

import AnimalsData
import AsyncSequenceTestUtils
import Collections
import ImmutableData
import Testing

final fileprivate class Error : Swift.Error {
  
}

final fileprivate class PersistentSessionPersistentStoreTestDouble : @unchecked Sendable, PersistentSessionPersistentStore {
  var fetchAnimalsQueryReturnAnimals: Array<Animal>? = nil
  var addAnimalMutationReturnAnimalId: String? = nil
  var updateAnimalMutationReturnAnimal: Bool = false
  var deleteAnimalMutationReturnName: String? = nil
  var deleteAnimalMutationReturnDiet: Animal.Diet? = nil
  var deleteAnimalMutationReturnCategoryId: String? = nil
  var fetchCategoriesQueryReturnCategories: Array<Category>? = nil
  var reloadSampleDataMutationReturnAnimals: Array<Animal>? = nil
  var reloadSampleDataMutationReturnCategories: Array<Category>? = nil
  let throwError = Error()
}

extension PersistentSessionPersistentStoreTestDouble {
  func fetchAnimalsQuery() async throws -> Array<Animal> {
    guard
      let returnAnimals = self.fetchAnimalsQueryReturnAnimals
    else {
      throw self.throwError
    }
    return returnAnimals
  }
}

extension PersistentSessionPersistentStoreTestDouble {
  func addAnimalMutation(
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal {
    guard
      let returnAnimalId = self.addAnimalMutationReturnAnimalId
    else {
      throw self.throwError
    }
    return Animal(
      animalId: returnAnimalId,
      name: name,
      diet: diet,
      categoryId: categoryId
    )
  }
}

extension PersistentSessionPersistentStoreTestDouble {
  func updateAnimalMutation(
    animalId: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal {
    guard
      self.updateAnimalMutationReturnAnimal
    else {
      throw self.throwError
    }
    return Animal(
      animalId: animalId,
      name: name,
      diet: diet,
      categoryId: categoryId
    )
  }
}

extension PersistentSessionPersistentStoreTestDouble {
  func deleteAnimalMutation(animalId: String) async throws -> Animal {
    guard
      let returnName = self.deleteAnimalMutationReturnName,
      let returnDiet = self.deleteAnimalMutationReturnDiet,
      let returnCategoryId = self.deleteAnimalMutationReturnCategoryId
    else {
      throw self.throwError
    }
    return Animal(
      animalId: animalId,
      name: returnName,
      diet: returnDiet,
      categoryId: returnCategoryId
    )
  }
}

extension PersistentSessionPersistentStoreTestDouble {
  func fetchCategoriesQuery() async throws -> Array<Category> {
    guard
      let returnCategories = self.fetchCategoriesQueryReturnCategories
    else {
      throw self.throwError
    }
    return returnCategories
  }
}

extension PersistentSessionPersistentStoreTestDouble {
  func reloadSampleDataMutation() async throws -> (
    animals: Array<Animal>,
    categories: Array<Category>
  ) {
    guard
      let returnAnimals = self.reloadSampleDataMutationReturnAnimals,
      let returnCategories = self.reloadSampleDataMutationReturnCategories
    else {
      throw self.throwError
    }
    return (animals: returnAnimals, categories: returnCategories)
  }
}

@MainActor final fileprivate class StoreTestDouble : Sendable {
  typealias State = AnimalsData.AnimalsState
  typealias Action = AnimalsData.AnimalsAction
  
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
  private let persistentStore = PersistentSessionPersistentStoreTestDouble()
}

extension ListenerTests {
  private static let state = AnimalsState(
    categories: AnimalsState.Categories(
      data: TreeDictionary(
        Category.amphibian,
        Category.bird,
        Category.fish,
        Category.invertebrate,
        Category.mammal,
        Category.reptile
      )
    ),
    animals: AnimalsState.Animals(
      data: TreeDictionary(
        Animal.dog,
        Animal.cat,
        Animal.kangaroo,
        Animal.gibbon,
        Animal.sparrow,
        Animal.newt
      )
    )
  )
}

extension ListenerTests {
  @Test func fetchAnimalsQueryFailure() async throws {
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(status: .waiting)
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.animalList(.onAppear))))
    
    #expect(await store.parameterAction.count == 1)
    
    let localizedDescription = try await #require(
      {
        if case .data(
          .persistentSession(
            .didFetchAnimals(
              result: .failure(
                error: let localizedDescription
              )
            )
          )
        ) = await store.parameterAction[0] {
          return localizedDescription
        }
        return nil
      }()
    )
    #expect(localizedDescription == self.persistentStore.throwError.localizedDescription)
  }
}

extension ListenerTests {
  @Test func fetchAnimalsQuerySuccess() async throws {
    self.persistentStore.fetchAnimalsQueryReturnAnimals = Array(Self.state.animals.data.values)
    
    let listener = await Listener(store: self.persistentStore)
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(status: .waiting)
      )
    )
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.animalList(.onAppear))))
    
    #expect(await store.parameterAction.count == 1)
    
    let animals = try await #require(
      {
        if case .data(
          .persistentSession(
            .didFetchAnimals(
              result: .success(
                animals: let animals
              )
            )
          )
        ) = await store.parameterAction[0] {
          return animals
        }
        return nil
      }()
    )
    #expect(animals == self.persistentStore.fetchAnimalsQueryReturnAnimals)
  }
}

extension ListenerTests {
  @Test func addAnimalMutationFailure() async throws {
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(
          queue: [ "id" : .waiting ]
        )
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.animalEditor(.onTapAddAnimalButton(id: "id", name: "name", diet: .herbivorous, categoryId: "categoryId")))))
    
    #expect(await store.parameterAction.count == 1)
    
    let (id, localizedDescription) = try await #require(
      {
        if case .data(
          .persistentSession(
            .didAddAnimal(
              id: let id,
              result: .failure(
                error: let localizedDescription
              )
            )
          )
        ) = await store.parameterAction[0] {
          return (id, localizedDescription)
        }
        return nil
      }()
    )
    #expect(id == "id")
    #expect(localizedDescription == self.persistentStore.throwError.localizedDescription)
  }
}

extension ListenerTests {
  @Test func addAnimalMutationSuccess() async throws {
    self.persistentStore.addAnimalMutationReturnAnimalId = "animalId"
    
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(
          queue: [ "id" : .waiting ]
        )
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.animalEditor(.onTapAddAnimalButton(id: "id", name: "name", diet: .herbivorous, categoryId: "categoryId")))))
    
    #expect(await store.parameterAction.count == 1)
    
    let (id, animal) = try await #require(
      {
        if case .data(
          .persistentSession(
            .didAddAnimal(
              id: let id,
              result: .success(
                animal: let animal
              )
            )
          )
        ) = await store.parameterAction[0] {
          return (id, animal)
        }
        return nil
      }()
    )
    #expect(id == "id")
    #expect(animal.animalId == self.persistentStore.addAnimalMutationReturnAnimalId)
    #expect(animal.name == "name")
    #expect(animal.diet == .herbivorous)
    #expect(animal.categoryId == "categoryId")
  }
}

extension ListenerTests {
  @Test func updateAnimalMutationFailure() async throws {
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(
          queue: [ "animalId" : .waiting ]
        )
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.animalEditor(.onTapUpdateAnimalButton(animalId: "animalId", name: "name", diet: .herbivorous, categoryId: "categoryId")))))
    
    #expect(await store.parameterAction.count == 1)
    
    let (animalId, localizedDescription) = try await #require(
      {
        if case .data(
          .persistentSession(
            .didUpdateAnimal(
              animalId: let animalId,
              result: .failure(
                error: let localizedDescription
              )
            )
          )
        ) = await store.parameterAction[0] {
          return (animalId, localizedDescription)
        }
        return nil
      }()
    )
    #expect(animalId == "animalId")
    #expect(localizedDescription == self.persistentStore.throwError.localizedDescription)
  }
}

extension ListenerTests {
  @Test func updateAnimalMutationSuccess() async throws {
    self.persistentStore.updateAnimalMutationReturnAnimal = true
    
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(
          queue: [ "animalId" : .waiting ]
        )
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.animalEditor(.onTapUpdateAnimalButton(animalId: "animalId", name: "name", diet: .herbivorous, categoryId: "categoryId")))))
    
    #expect(await store.parameterAction.count == 1)
    
    let (animalId, animal) = try await #require(
      {
        if case .data(
          .persistentSession(
            .didUpdateAnimal(
              animalId: let animalId,
              result: .success(
                animal: let animal
              )
            )
          )
        ) = await store.parameterAction[0] {
          return (animalId, animal)
        }
        return nil
      }()
    )
    #expect(animalId == "animalId")
    #expect(animal.animalId == "animalId")
    #expect(animal.name == "name")
    #expect(animal.diet == .herbivorous)
    #expect(animal.categoryId == "categoryId")
  }
}

extension ListenerTests {
  @Test(
    arguments: [
      AnimalsAction.ui(.animalList(.onTapDeleteSelectedAnimalButton(animalId: "animalId"))),
      AnimalsAction.ui(.animalDetail(.onTapDeleteSelectedAnimalButton(animalId: "animalId")))
    ]
  ) func deleteAnimalMutationFailure(
    action: AnimalsAction
  ) async throws {
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(
          queue: [ "animalId" : .waiting ]
        )
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: action))
    
    #expect(await store.parameterAction.count == 1)
    
    let (animalId, localizedDescription) = try await #require(
      {
        if case .data(
          .persistentSession(
            .didDeleteAnimal(
              animalId: let animalId,
              result: .failure(
                error: let localizedDescription
              )
            )
          )
        ) = await store.parameterAction[0] {
          return (animalId, localizedDescription)
        }
        return nil
      }()
    )
    #expect(animalId == "animalId")
    #expect(localizedDescription == self.persistentStore.throwError.localizedDescription)
  }
}

extension ListenerTests {
  @Test(
    arguments: [
      AnimalsAction.ui(.animalList(.onTapDeleteSelectedAnimalButton(animalId: "animalId"))),
      AnimalsAction.ui(.animalDetail(.onTapDeleteSelectedAnimalButton(animalId: "animalId")))
    ]
  ) func deleteAnimalMutationSuccess(
    action: AnimalsAction
  ) async throws {
    self.persistentStore.deleteAnimalMutationReturnName = "name"
    self.persistentStore.deleteAnimalMutationReturnDiet = .herbivorous
    self.persistentStore.deleteAnimalMutationReturnCategoryId = "categoryId"
    
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(),
        animals: AnimalsState.Animals(
          queue: [ "animalId" : .waiting ]
        )
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: action))
    
    #expect(await store.parameterAction.count == 1)
    
    let (animalId, animal) = try await #require(
      {
        if case .data(
          .persistentSession(
            .didDeleteAnimal(
              animalId: let animalId,
              result: .success(
                animal: let animal
              )
            )
          )
        ) = await store.parameterAction[0] {
          return (animalId, animal)
        }
        return nil
      }()
    )
    #expect(animalId == "animalId")
    #expect(animal.animalId == "animalId")
    #expect(animal.name == "name")
    #expect(animal.diet == .herbivorous)
    #expect(animal.categoryId == "categoryId")
  }
}

extension ListenerTests {
  @Test func fetchCategoriesQueryFailure() async throws {
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(status: .waiting),
        animals: AnimalsState.Animals()
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.categoryList(.onAppear))))
    
    #expect(await store.parameterAction.count == 1)
    
    let localizedDescription = try await #require(
      {
        if case .data(
          .persistentSession(
            .didFetchCategories(
              result: .failure(
                error: let localizedDescription
              )
            )
          )
        ) = await store.parameterAction[0] {
          return localizedDescription
        }
        return nil
      }()
    )
    #expect(localizedDescription == self.persistentStore.throwError.localizedDescription)
  }
}

extension ListenerTests {
  @Test func fetchCategoriesQuerySuccess() async throws {
    self.persistentStore.fetchCategoriesQueryReturnCategories = Array(Self.state.categories.data.values)
    
    let listener = await Listener(store: self.persistentStore)
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(status: .waiting),
        animals: AnimalsState.Animals()
      )
    )
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.categoryList(.onAppear))))
    
    #expect(await store.parameterAction.count == 1)
    
    let categories = try await #require(
      {
        if case .data(
          .persistentSession(
            .didFetchCategories(
              result: .success(
                categories: let categories
              )
            )
          )
        ) = await store.parameterAction[0] {
          return categories
        }
        return nil
      }()
    )
    #expect(categories == self.persistentStore.fetchCategoriesQueryReturnCategories)
  }
}

extension ListenerTests {
  @Test func reloadSampleDataMutationFailure() async throws {
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(status: .waiting),
        animals: AnimalsState.Animals(status: .waiting)
      )
    )
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.categoryList(.onTapReloadSampleDataButton))))
    
    #expect(await store.parameterAction.count == 1)
    
    let localizedDescription = try await #require(
      {
        if case .data(
          .persistentSession(
            .didReloadSampleData(
              result: .failure(
                error: let localizedDescription
              )
            )
          )
        ) = await store.parameterAction[0] {
          return localizedDescription
        }
        return nil
      }()
    )
    #expect(localizedDescription == self.persistentStore.throwError.localizedDescription)
  }
}

extension ListenerTests {
  @Test func reloadSampleDataMutationSuccess() async throws {
    self.persistentStore.reloadSampleDataMutationReturnAnimals = Array(Self.state.animals.data.values)
    self.persistentStore.reloadSampleDataMutationReturnCategories = Array(Self.state.categories.data.values)
    
    let listener = await Listener(store: self.persistentStore)
    let store = await StoreTestDouble(
      returnState: AnimalsState(
        categories: AnimalsState.Categories(status: .waiting),
        animals: AnimalsState.Animals(status: .waiting)
      )
    )
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: .ui(.categoryList(.onTapReloadSampleDataButton))))
    
    #expect(await store.parameterAction.count == 1)
    
    let (animals, categories) = try await #require(
      {
        if case .data(
          .persistentSession(
            .didReloadSampleData(
              result: .success(
                animals: let animals,
                categories: let categories
              )
            )
          )
        ) = await store.parameterAction[0] {
          return (animals, categories)
        }
        return nil
      }()
    )
    #expect(animals == self.persistentStore.reloadSampleDataMutationReturnAnimals)
    #expect(categories == self.persistentStore.reloadSampleDataMutationReturnCategories)
  }
}

extension ListenerTests {
  @Test(
    arguments: [
      AnimalsAction.data(.persistentSession(.didFetchCategories(result: .success(categories: Array(Self.state.categories.data.values))))),
      AnimalsAction.data(.persistentSession(.didFetchCategories(result: .failure(error: "error")))),
      AnimalsAction.data(.persistentSession(.didFetchAnimals(result: .success(animals: Array(Self.state.animals.data.values))))),
      AnimalsAction.data(.persistentSession(.didFetchAnimals(result: .failure(error: "error")))),
      AnimalsAction.data(.persistentSession(.didAddAnimal(id: "id", result: .success(animal: Animal(animalId: "animalId", name: "name", diet: .herbivorous, categoryId: "categoryId"))))),
      AnimalsAction.data(.persistentSession(.didAddAnimal(id: "id", result: .failure(error: "error")))),
      AnimalsAction.data(.persistentSession(.didUpdateAnimal(animalId: "animalId", result: .success(animal: Animal(animalId: "animalId", name: "name", diet: .herbivorous, categoryId: "categoryId"))))),
      AnimalsAction.data(.persistentSession(.didUpdateAnimal(animalId: "animalId", result: .failure(error: "error")))),
      AnimalsAction.data(.persistentSession(.didDeleteAnimal(animalId: "animalId", result: .success(animal: Animal(animalId: "animalId", name: "name", diet: .herbivorous, categoryId: "categoryId"))))),
      AnimalsAction.data(.persistentSession(.didDeleteAnimal(animalId: "animalId", result: .failure(error: "error"))))
    ]
  ) func doesNothing(
    action: AnimalsAction
  ) async {
    let store = await StoreTestDouble(returnState: AnimalsState())
    let listener = await Listener(store: self.persistentStore)
    
    await listener.listen(to: store)
    
    await store.sequence.iterator.resume(returning: (oldState: AnimalsState(), action: action))
    
    #expect(await store.parameterAction.isEmpty)
  }
}
