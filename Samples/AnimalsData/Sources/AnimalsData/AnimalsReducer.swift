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

import Collections

public enum AnimalsReducer {
  @Sendable public static func reduce(
    state: AnimalsState,
    action: AnimalsAction
  ) throws -> AnimalsState {
    switch action {
    case .ui(action: let action):
      return try self.reduce(state: state, action: action)
    case .data(action: let action):
      return try self.reduce(state: state, action: action)
    }
  }
}

extension AnimalsReducer {
  private static func reduce(
    state: AnimalsState,
    action: AnimalsAction.UI
  ) throws -> AnimalsState {
    switch action {
    case .categoryList(action: let action):
      return try self.reduce(state: state, action: action)
    case .animalList(action: let action):
      return try self.reduce(state: state, action: action)
    case .animalDetail(action: let action):
      return try self.reduce(state: state, action: action)
    case .animalEditor(action: let action):
      return try self.reduce(state: state, action: action)
    }
  }
}

extension AnimalsReducer {
  private static func reduce(
    state: AnimalsState,
    action: AnimalsAction.UI.CategoryList
  ) throws -> AnimalsState {
    switch action {
    case .onAppear:
      if state.categories.status == nil {
        var state = state
        state.categories.status = .waiting
        return state
      }
      return state
    case .onTapReloadSampleDataButton:
      if state.categories.status != .waiting,
         state.animals.status != .waiting {
        var state = state
        state.categories.status = .waiting
        state.animals.status = .waiting
        return state
      }
      return state
    }
  }
}

extension AnimalsReducer {
  package struct Error: Swift.Error {
    package enum Code: Hashable, Sendable {
      case animalNotFound
    }
    
    package let code: Self.Code
  }
}

extension AnimalsState {
  fileprivate func onTapDeleteSelectedAnimalButton(animalId: Animal.ID) throws -> Self {
    guard let _ = self.animals.data[animalId] else {
      throw AnimalsReducer.Error(code: .animalNotFound)
    }
    var state = self
    state.animals.queue[animalId] = .waiting
    return state
  }
}

extension AnimalsReducer {
  private static func reduce(
    state: AnimalsState,
    action: AnimalsAction.UI.AnimalList
  ) throws -> AnimalsState {
    switch action {
    case .onAppear:
      if state.animals.status == nil {
        var state = state
        state.animals.status = .waiting
        return state
      }
      return state
    case .onTapDeleteSelectedAnimalButton(animalId: let animalId):
      return try state.onTapDeleteSelectedAnimalButton(animalId: animalId)
    }
  }
}

extension AnimalsReducer {
  private static func reduce(
    state: AnimalsState,
    action: AnimalsAction.UI.AnimalDetail
  ) throws -> AnimalsState {
    switch action {
    case .onTapDeleteSelectedAnimalButton(animalId: let animalId):
      return try state.onTapDeleteSelectedAnimalButton(animalId: animalId)
    }
  }
}

extension AnimalsState {
  fileprivate func onTapAddAnimalButton(
    id: Animal.ID,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) -> Self {
    var state = self
    state.animals.queue[id] = .waiting
    return state
  }
}

extension AnimalsState {
  fileprivate func onTapUpdateAnimalButton(
    animalId: Animal.ID,
    name: String,
    diet: Animal.Diet,
    categoryId: Category.ID
  ) throws -> Self {
    guard let _ = self.animals.data[animalId] else {
      throw AnimalsReducer.Error(code: .animalNotFound)
    }
    var state = self
    state.animals.queue[animalId] = .waiting
    return state
  }
}

extension AnimalsReducer {
  private static func reduce(
    state: AnimalsState,
    action: AnimalsAction.UI.AnimalEditor
  ) throws -> AnimalsState {
    switch action {
    case .onTapAddAnimalButton(id: let id, name: let name, diet: let diet, categoryId: let categoryId):
      return state.onTapAddAnimalButton(id: id, name: name, diet: diet, categoryId: categoryId)
    case .onTapUpdateAnimalButton(animalId: let animalId, name: let name, diet: let diet, categoryId: let categoryId):
      return try state.onTapUpdateAnimalButton(animalId: animalId, name: name, diet: diet, categoryId: categoryId)
    }
  }
}

extension AnimalsReducer {
  private static func reduce(
    state: AnimalsState,
    action: AnimalsAction.Data
  ) throws -> AnimalsState {
    switch action {
    case .persistentSession(.didFetchCategories(result: let result)):
      return self.persistentSessionDidFetchCategories(state: state, result: result)
    case .persistentSession(.didFetchAnimals(result: let result)):
      return self.persistentSessionDidFetchAnimals(state: state, result: result)
    case .persistentSession(.didReloadSampleData(result: let result)):
      return self.persistentSessionDidReloadSampleData(state: state, result: result)
    case .persistentSession(.didAddAnimal(id: let id, result: let result)):
      return self.persistentSessionDidAddAnimal(state: state, id: id, result: result)
    case .persistentSession(.didUpdateAnimal(animalId: let animalId, result: let result)):
      return try self.persistentSessionDidUpdateAnimal(state: state, animalId: animalId, result: result)
    case .persistentSession(.didDeleteAnimal(animalId: let animalId, result: let result)):
      return try self.persistentSessionDidDeleteAnimal(state: state, animalId: animalId, result: result)
    }
  }
}

extension AnimalsReducer {
  private static func persistentSessionDidFetchCategories(
    state: AnimalsState,
    result: AnimalsAction.Data.PersistentSession.FetchCategoriesResult
  ) -> AnimalsState {
    var state = state
    switch result {
    case .success(categories: let categories):
      var data = state.categories.data
      for category in categories {
        data[category.id] = category
      }
      state.categories.data = data
      state.categories.status = .success
    case .failure(error: let error):
      state.categories.status = .failure(error: error)
    }
    return state
  }
}

extension AnimalsReducer {
  private static func persistentSessionDidFetchAnimals(
    state: AnimalsState,
    result: AnimalsAction.Data.PersistentSession.FetchAnimalsResult
  ) -> AnimalsState {
    var state = state
    switch result {
    case .success(animals: let animals):
      var data = state.animals.data
      for animal in animals {
        data[animal.id] = animal
      }
      state.animals.data = data
      state.animals.status = .success
    case .failure(error: let error):
      state.animals.status = .failure(error: error)
    }
    return state
  }
}

extension AnimalsReducer {
  private static func persistentSessionDidReloadSampleData(
    state: AnimalsState,
    result: AnimalsAction.Data.PersistentSession.ReloadSampleDataResult
  ) -> AnimalsState {
    var state = state
    switch result {
    case .success(animals: let animals, categories: let categories):
      do {
        var data: TreeDictionary<Animal.ID, Animal> = [:]
        for animal in animals {
          data[animal.id] = animal
        }
        state.animals.data = data
        state.animals.status = .success
      }
      do {
        var data: TreeDictionary<Category.ID, Category> = [:]
        for category in categories {
          data[category.id] = category
        }
        state.categories.data = data
        state.categories.status = .success
      }
    case .failure(error: let error):
      state.animals.status = .failure(error: error)
      state.categories.status = .failure(error: error)
    }
    return state
  }
}

extension AnimalsReducer {
  private static func persistentSessionDidAddAnimal(
    state: AnimalsState,
    id: Animal.ID,
    result: AnimalsAction.Data.PersistentSession.AddAnimalResult
  ) -> AnimalsState {
    var state = state
    switch result {
    case .success(animal: let animal):
      state.animals.data[animal.id] = animal
      state.animals.queue[id] = .success
    case .failure(error: let error):
      state.animals.queue[id] = .failure(error: error)
    }
    return state
  }
}

extension AnimalsReducer {
  private static func persistentSessionDidUpdateAnimal(
    state: AnimalsState,
    animalId: Animal.ID,
    result: AnimalsAction.Data.PersistentSession.UpdateAnimalResult
  ) throws -> AnimalsState {
    guard let _ = state.animals.data[animalId] else {
      throw AnimalsReducer.Error(code: .animalNotFound)
    }
    var state = state
    switch result {
    case .success(animal: let animal):
      state.animals.data[animalId] = animal
      state.animals.queue[animalId] = .success
    case .failure(error: let error):
      state.animals.queue[animalId] = .failure(error: error)
    }
    return state
  }
}

extension AnimalsReducer {
  private static func persistentSessionDidDeleteAnimal(
    state: AnimalsState,
    animalId: Animal.ID,
    result: AnimalsAction.Data.PersistentSession.DeleteAnimalResult
  ) throws -> AnimalsState {
    guard let _ = state.animals.data[animalId] else {
      throw AnimalsReducer.Error(code: .animalNotFound)
    }
    var state = state
    switch result {
    case .success(animal: let animal):
      state.animals.data[animal.id] = nil
      state.animals.queue[animal.id] = .success
    case .failure(error: let error):
      state.animals.queue[animalId] = .failure(error: error)
    }
    return state
  }
}
