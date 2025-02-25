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
import SwiftData

@Model final package class CategoryModel {
  package var categoryId: Category.ID
  package var name: String
  
  package init(
    categoryId: Category.ID,
    name: String
  ) {
    self.categoryId = categoryId
    self.name = name
  }
}

extension CategoryModel {
  fileprivate func category() -> Category {
    Category(
      categoryId: self.categoryId,
      name: self.name
    )
  }
}

extension Category {
  fileprivate func model() -> CategoryModel {
    CategoryModel(
      categoryId: self.categoryId,
      name: self.name
    )
  }
}

@Model final package class AnimalModel {
  package var animalId: Animal.ID
  package var name: String
  package var diet: String
  package var categoryId: Category.ID
  
  package init(
    animalId: Animal.ID,
    name: String,
    diet: String,
    categoryId: Category.ID
  ) {
    self.animalId = animalId
    self.name = name
    self.diet = diet
    self.categoryId = categoryId
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

extension Animal {
  fileprivate func model() -> AnimalModel {
    AnimalModel(
      animalId: self.animalId,
      name: self.name,
      diet: self.diet.rawValue,
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

extension ModelContext {
  fileprivate func fetchCount<T>(_ type: T.Type) throws -> Int where T : PersistentModel {
    try self.fetchCount(
      FetchDescriptor<T>()
    )
  }
}

extension ModelContext {
  fileprivate func fetchCount<T>(_ predicate: Predicate<T>) throws -> Int where T : PersistentModel {
    try self.fetchCount(
      FetchDescriptor(predicate: predicate)
    )
  }
}

public protocol IncrementalStoreUUID {
  var uuidString: String { get }
  
  init()
}

extension UUID : IncrementalStoreUUID {
  
}

final package actor ModelActor<UUID> : SwiftData.ModelActor where UUID : IncrementalStoreUUID {
  package nonisolated let modelContainer: ModelContainer
  package nonisolated let modelExecutor: any ModelExecutor
  
  fileprivate init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    let modelContext = ModelContext(modelContainer)
    modelContext.autosaveEnabled = false
    do {
      let count = try modelContext.fetchCount(CategoryModel.self)
      if count == .zero {
        modelContext.insert(Category.amphibian.model())
        modelContext.insert(Category.bird.model())
        modelContext.insert(Category.fish.model())
        modelContext.insert(Category.invertebrate.model())
        modelContext.insert(Category.mammal.model())
        modelContext.insert(Category.reptile.model())
        
        modelContext.insert(Animal.dog.model())
        modelContext.insert(Animal.cat.model())
        modelContext.insert(Animal.kangaroo.model())
        modelContext.insert(Animal.gibbon.model())
        modelContext.insert(Animal.sparrow.model())
        modelContext.insert(Animal.newt.model())
        
        try modelContext.save()
      }
    } catch {
      fatalError("\(error)")
    }
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
  }
}

extension ModelActor {
  fileprivate func fetchCategoriesQuery() throws -> Array<Category> {
    let array = try self.modelContext.fetch(CategoryModel.self)
    return array.map { model in model.category() }
  }
}

extension ModelActor {
  fileprivate func fetchAnimalsQuery() throws -> Array<Animal> {
    let array = try self.modelContext.fetch(AnimalModel.self)
    return array.map { model in model.animal() }
  }
}

extension ModelActor {
  fileprivate func addAnimalMutation(
    name: String,
    diet: Animal.Diet,
    categoryId: Category.ID
  ) throws -> Animal {
    let animal = Animal(
      animalId: UUID().uuidString,
      name: name,
      diet: diet,
      categoryId: categoryId
    )
    let model = animal.model()
    self.modelContext.insert(model)
    try self.modelContext.save()
    return animal
  }
}

extension ModelActor {
  package struct Error: Swift.Error {
    package enum Code: Hashable, Sendable {
      case animalNotFound
    }
    
    package let code: Self.Code
  }
}

extension ModelActor {
  fileprivate func updateAnimalMutation(
    animalId: Animal.ID,
    name: String,
    diet: Animal.Diet,
    categoryId: Category.ID
  ) throws -> Animal {
    let predicate = #Predicate<AnimalModel> { model in
      model.animalId == animalId
    }
    let array = try self.modelContext.fetch(predicate)
    guard
      let model = array.first
    else {
      throw Self.Error(code: .animalNotFound)
    }
    model.name = name
    model.diet = diet.rawValue
    model.categoryId = categoryId
    try self.modelContext.save()
    let animal = model.animal()
    return animal
  }
}

extension ModelActor {
  fileprivate func deleteAnimalMutation(animalId: Animal.ID) throws -> Animal {
    let predicate = #Predicate<AnimalModel> { model in
      model.animalId == animalId
    }
    let array = try self.modelContext.fetch(predicate)
    guard
      let model = array.first
    else {
      throw Self.Error(code: .animalNotFound)
    }
    self.modelContext.delete(model)
    try self.modelContext.save()
    return model.animal()
  }
}

extension ModelActor {
  fileprivate func reloadSampleDataMutation() throws -> (
    animals: Array<Animal>,
    categories: Array<Category>
  ) {
    try self.modelContext.delete(model: CategoryModel.self)
    self.modelContext.insert(Category.amphibian.model())
    self.modelContext.insert(Category.bird.model())
    self.modelContext.insert(Category.fish.model())
    self.modelContext.insert(Category.invertebrate.model())
    self.modelContext.insert(Category.mammal.model())
    self.modelContext.insert(Category.reptile.model())
    
    try self.modelContext.delete(model: AnimalModel.self)
    self.modelContext.insert(Animal.dog.model())
    self.modelContext.insert(Animal.cat.model())
    self.modelContext.insert(Animal.kangaroo.model())
    self.modelContext.insert(Animal.gibbon.model())
    self.modelContext.insert(Animal.sparrow.model())
    self.modelContext.insert(Animal.newt.model())
    
    try self.modelContext.save()
    
    return (
      animals: [
        Animal.dog,
        Animal.cat,
        Animal.kangaroo,
        Animal.gibbon,
        Animal.sparrow,
        Animal.newt,
      ],
      categories: [
        Category.amphibian,
        Category.bird,
        Category.fish,
        Category.invertebrate,
        Category.mammal,
        Category.reptile,
      ]
    )
  }
}

final public actor LocalStore<UUID> where UUID : IncrementalStoreUUID {
  lazy package var modelActor = ModelActor<UUID>(modelContainer: self.modelContainer)
  
  private let modelContainer: ModelContainer
  
  private init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }
}

extension LocalStore {
  private init(
    schema: Schema,
    configuration: ModelConfiguration
  ) throws {
    let container = try ModelContainer(
      for: schema,
      configurations: configuration
    )
    self.init(modelContainer: container)
  }
}

extension LocalStore {
  private static var models: Array<any PersistentModel.Type> {
    [AnimalModel.self, CategoryModel.self]
  }
}

extension LocalStore {
  public init(url: URL) throws {
    let schema = Schema(Self.models)
    let configuration = ModelConfiguration(url: url)
    try self.init(
      schema: schema,
      configuration: configuration
    )
  }
}

extension LocalStore {
  public init(isStoredInMemoryOnly: Bool = false) throws {
    let schema = Schema(Self.models)
    let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
    try self.init(
      schema: schema,
      configuration: configuration
    )
  }
}

extension LocalStore: PersistentSessionPersistentStore {
  public func fetchAnimalsQuery() async throws -> Array<Animal> {
    try await self.modelActor.fetchAnimalsQuery()
  }
  
  public func addAnimalMutation(
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal {
    try await self.modelActor.addAnimalMutation(
      name: name,
      diet: diet,
      categoryId: categoryId
    )
  }
  
  public func updateAnimalMutation(
    animalId: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal {
    try await self.modelActor.updateAnimalMutation(
      animalId: animalId,
      name: name,
      diet: diet,
      categoryId: categoryId
    )
  }
  
  public func deleteAnimalMutation(animalId: String) async throws -> Animal {
    try await self.modelActor.deleteAnimalMutation(animalId: animalId)
  }
  
  public func fetchCategoriesQuery() async throws -> Array<Category> {
    try await self.modelActor.fetchCategoriesQuery()
  }
  
  public func reloadSampleDataMutation() async throws -> (
    animals: Array<Animal>,
    categories: Array<Category>
  ) {
    try await self.modelActor.reloadSampleDataMutation()
  }
}
