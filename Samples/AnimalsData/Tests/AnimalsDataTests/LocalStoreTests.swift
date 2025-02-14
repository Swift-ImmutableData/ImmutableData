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
import Collections
import Foundation
import SwiftData
import Testing

//  https://github.com/swiftlang/swift/issues/74882

extension CategoryModel {
  fileprivate func category() -> AnimalsData.Category {
    Category(
      categoryId: self.categoryId,
      name: self.name
    )
  }
}

extension AnimalModel {
  fileprivate func animal() -> Animal {
    guard
      let diet = Animal.Diet(rawValue: self.diet)
    else {
      fatalError("missing diet")
    }
    return Animal(
      animalId: self.animalId,
      name: self.name,
      diet: diet,
      categoryId: self.categoryId
    )
  }
}

extension ModelContext {
  fileprivate func fetch<T>(_ type: T.Type) throws -> Array<T> where T : PersistentModel {
    try self.fetch(
      FetchDescriptor<T>()
    )
  }
}

extension ModelContext {
  fileprivate func fetch<T>(_ predicate: Predicate<T>) throws -> Array<T> where T : PersistentModel {
    try self.fetch(
      FetchDescriptor(predicate: predicate)
    )
  }
}

final fileprivate class IncrementalStoreUUIDTestDouble : IncrementalStoreUUID {
  var uuidString: String {
    "uuidString"
  }
  
  init() {
    
  }
}

@Suite(.serialized) final actor LocalStoreTests {
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

extension LocalStoreTests {
  private static func makeStore() throws -> LocalStore<IncrementalStoreUUIDTestDouble> {
    let store = try LocalStore<IncrementalStoreUUIDTestDouble>(isStoredInMemoryOnly: true)
    return store
  }
}

extension LocalStoreTests {
  @Test func fetchCategoriesQuery() async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    let categories = try await store.fetchCategoriesQuery()
    #expect(TreeDictionary(categories) == Self.state.categories.data)
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test func fetchAnimalsQuery() async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    let animals = try await store.fetchAnimalsQuery()
    #expect(TreeDictionary(animals) == Self.state.animals.data)
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test func addAnimalMutation() async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    let animal = try await store.addAnimalMutation(
      name: "name",
      diet: .herbivorous,
      categoryId: "categoryId"
    )
    #expect(animal.id == "uuidString")
    #expect(animal.name == "name")
    #expect(animal.diet == .herbivorous)
    #expect(animal.categoryId == "categoryId")
    
    let array = try modelActor.modelExecutor.modelContext.fetch(AnimalModel.self)
    let animals = array.map { model in model.animal() }
    #expect(
      TreeDictionary(animals) == {
        var data = Self.state.animals.data
        data["uuidString"] = Animal(
          animalId: "uuidString",
          name: "name",
          diet: .herbivorous,
          categoryId: "categoryId"
        )
      return data
    }())
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test(arguments: Self.state.animals.data.values) func updateAnimalMutation(animal: Animal) async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    let updatedAnimal = try await store.updateAnimalMutation(
      animalId: animal.id,
      name: "name",
      diet: .herbivorous,
      categoryId: "categoryId"
    )
    #expect(updatedAnimal.id == animal.id)
    #expect(updatedAnimal.name == "name")
    #expect(updatedAnimal.diet == .herbivorous)
    #expect(updatedAnimal.categoryId == "categoryId")
    
    let array = try modelActor.modelExecutor.modelContext.fetch(AnimalModel.self)
    let animals = array.map { model in model.animal() }
    #expect(
      TreeDictionary(animals) == {
        var data = Self.state.animals.data
        data[animal.id] = Animal(
          animalId: animal.id,
          name: "name",
          diet: .herbivorous,
          categoryId: "categoryId"
        )
      return data
    }())
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test(arguments: Self.state.animals.data.values) func updateAnimalMutationThrows(animal: Animal) async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    let animalId = animal.id
    let predicate = #Predicate<AnimalModel> { model in
      model.animalId == animalId
    }
    try modelActor.modelExecutor.modelContext.delete(
      model: AnimalModel.self,
      where: predicate
    )
    try modelActor.modelExecutor.modelContext.save()
    do {
      let _ = try await store.updateAnimalMutation(
        animalId: animal.id,
        name: "name",
        diet: .herbivorous,
        categoryId: "categoryId"
      )
      #expect(false)
    } catch {
      let error = try #require(error as? AnimalsData.ModelActor<IncrementalStoreUUIDTestDouble>.Error)
      #expect(error.code == .animalNotFound)
    }
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test(arguments: Self.state.animals.data.values) func deleteAnimalMutation(animal: Animal) async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    let deletedAnimal = try await store.deleteAnimalMutation(
      animalId: animal.id
    )
    #expect(deletedAnimal == animal)
    
    let array = try modelActor.modelExecutor.modelContext.fetch(AnimalModel.self)
    let animals = array.map { model in model.animal() }
    #expect(
      TreeDictionary(animals) == {
        var data = Self.state.animals.data
        data[animal.id] = nil
      return data
    }())
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test(arguments: Self.state.animals.data.values) func deleteAnimalMutationThrows(animal: Animal) async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    let animalId = animal.id
    let predicate = #Predicate<AnimalModel> { model in
      model.animalId == animalId
    }
    try modelActor.modelExecutor.modelContext.delete(
      model: AnimalModel.self,
      where: predicate
    )
    try modelActor.modelExecutor.modelContext.save()
    do {
      let _ = try await store.deleteAnimalMutation(animalId: animal.id)
      #expect(false)
    } catch {
      let error = try #require(error as? AnimalsData.ModelActor<IncrementalStoreUUIDTestDouble>.Error)
      #expect(error.code == .animalNotFound)
    }
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test func reloadSampleDataMutation() async throws {
    let store = try Self.makeStore()
    let modelActor = await store.modelActor
    
    modelActor.modelExecutor.modelContext.insert(
      CategoryModel(
        categoryId: "categoryId",
        name: "name"
      )
    )
    modelActor.modelExecutor.modelContext.insert(
      AnimalModel(
        animalId: "animalId",
        name: "name",
        diet: "Herbivore",
        categoryId: "categoryId"
      )
    )
    try modelActor.modelExecutor.modelContext.save()
    let (animals, categories) = try await store.reloadSampleDataMutation()
    #expect(TreeDictionary(animals) == Self.state.animals.data)
    #expect(TreeDictionary(categories) == Self.state.categories.data)
    
    do {
      let array = try modelActor.modelExecutor.modelContext.fetch(AnimalModel.self)
      let animals = array.map { model in model.animal() }
      #expect(TreeDictionary(animals) == Self.state.animals.data)
    }
    do {
      let array = try modelActor.modelExecutor.modelContext.fetch(CategoryModel.self)
      let categories = array.map { model in model.category() }
      #expect(TreeDictionary(categories) == Self.state.categories.data)
    }
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}
