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
import Testing

@Suite final actor AnimalsReducerTests {
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

extension AnimalsReducerTests {
  @Test func uiCategoriesListOnAppear() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .ui(
        .categoryList(
          .onAppear
        )
      )
    )
    
    #expect(
      state.animals == Self.state.animals
    )
    #expect(
      state.categories.data == Self.state.categories.data
    )
    #expect(
      state.categories.status == .waiting
    )
  }
}

extension AnimalsReducerTests {
  @Test func uiCategoriesListOnTapReloadSampleDataButton() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .ui(
        .categoryList(
          .onTapReloadSampleDataButton
        )
      )
    )
    
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == .waiting
    )
    #expect(
      state.animals.queue == Self.state.animals.queue
    )
    #expect(
      state.categories.data == Self.state.categories.data
    )
    #expect(
      state.categories.status == .waiting
    )
  }
}

extension AnimalsReducerTests {
  @Test func uiAnimalsListOnAppear() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .ui(
        .animalList(
          .onAppear
        )
      )
    )
    
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == .waiting
    )
    #expect(
      state.animals.queue == Self.state.animals.queue
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func uiAnimalsListOnTapDeleteSelectedAnimalButton(animal: Animal) throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .ui(
        .animalList(
          .onTapDeleteSelectedAnimalButton(
            animalId: animal.id
          )
        )
      )
    )
    
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == [animal.id : .waiting]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func uiAnimalsListOnTapDeleteSelectedAnimalButtonThrows(animal: Animal) {
    var state = Self.state
    state.animals.data[animal.id] = nil
    #expect {
      let _ = try AnimalsReducer.reduce(
        state: state,
        action: .ui(
          .animalList(
            .onTapDeleteSelectedAnimalButton(
              animalId: animal.id
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? AnimalsReducer.Error
      )
      return error.code == .animalNotFound
    }
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func uiAnimalsDetailOnTapDeleteSelectedAnimalButton(animal: Animal) throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .ui(
        .animalDetail(
          .onTapDeleteSelectedAnimalButton(
            animalId: animal.id
          )
        )
      )
    )
    
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == [animal.id : .waiting]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func uiAnimalsDetailOnTapDeleteSelectedAnimalButtonThrows(animal: Animal) {
    var state = Self.state
    state.animals.data[animal.id] = nil
    #expect {
      let _ = try AnimalsReducer.reduce(
        state: state,
        action: .ui(
          .animalDetail(
            .onTapDeleteSelectedAnimalButton(
              animalId: animal.id
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? AnimalsReducer.Error
      )
      return error.code == .animalNotFound
    }
  }
}

extension AnimalsReducerTests {
  @Test func uiAnimalsEditorOnTapAddAnimalButton() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .ui(
        .animalEditor(
          .onTapAddAnimalButton(
            id: "id",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        )
      )
    )
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == ["id" : .waiting]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func uiAnimalsEditorOnTapUpdateAnimalButton(animal: Animal) throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .ui(
        .animalEditor(
          .onTapUpdateAnimalButton(
            animalId: animal.id,
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        )
      )
    )
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == [animal.id : .waiting]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func uiAnimalsEditorOnTapUpdateAnimalButtonThrows(animal: Animal) {
    var state = Self.state
    state.animals.data[animal.id] = nil
    #expect {
      let _ = try AnimalsReducer.reduce(
        state: state,
        action: .ui(
          .animalEditor(
            .onTapUpdateAnimalButton(
              animalId: animal.id,
              name: "name",
              diet: .herbivorous,
              categoryId: "categoryId"
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? AnimalsReducer.Error
      )
      return error.code == .animalNotFound
    }
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidFetchCategoriesSuccess() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didFetchCategories(
            result: .success(
              categories: [
                Category(
                  categoryId: "categoryId",
                  name: "name"
                )
              ]
            )
          )
        )
      )
    )
    #expect(
      state.animals == Self.state.animals
    )
    #expect(
      state.categories.data == TreeDictionary(
        Self.state.categories.data.values + [
          Category(
            categoryId: "categoryId",
            name: "name"
          )
        ]
      )
    )
    #expect(
      state.categories.status == .success
    )
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidFetchCategoriesFailure() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didFetchCategories(
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    #expect(
      state.animals == Self.state.animals
    )
    #expect(
      state.categories.data == Self.state.categories.data
    )
    #expect(
      state.categories.status == .failure(
        error: "error"
      )
    )
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidFetchAnimalsSuccess() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didFetchAnimals(
            result: .success(
              animals: [
                Animal(
                  animalId: "animalId",
                  name: "name",
                  diet: .herbivorous,
                  categoryId: "categoryId"
                )
              ]
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == TreeDictionary(
        Self.state.animals.data.values + [
          Animal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
    #expect(
      state.animals.status == .success
    )
    #expect(
      state.animals.queue == [:]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidFetchAnimalsFailure() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didFetchAnimals(
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.queue == [:]
    )
    #expect(
      state.animals.status == .failure(
        error: "error"
      )
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidReloadSampleDataSuccess() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didReloadSampleData(
            result: .success(
              animals: [
                Animal(
                  animalId: "animalId",
                  name: "name",
                  diet: .herbivorous,
                  categoryId: "categoryId"
                )
              ],
              categories: [
                Category(
                  categoryId: "categoryId",
                  name: "name"
                )
              ]
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == TreeDictionary(
        Animal(
          animalId: "animalId",
          name: "name",
          diet: .herbivorous,
          categoryId: "categoryId"
        )

      )
    )
    #expect(
      state.animals.status == .success
    )
    #expect(
      state.animals.queue == [:]
    )
    #expect(
      state.categories.data == TreeDictionary(
        Category(
          categoryId: "categoryId",
          name: "name"
        )
      )
    )
    #expect(
      state.categories.status == .success
    )
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidReloadSampleDataFailure() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didReloadSampleData(
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == .failure(
        error: "error"
      )
    )
    #expect(
      state.animals.queue == [:]
    )
    #expect(
      state.categories.data == Self.state.categories.data
    )
    #expect(
      state.categories.status == .failure(
        error: "error"
      )
    )
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidAddAnimalSuccess() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didAddAnimal(
            id: "id",
            result: .success(
              animal: Animal(
                animalId: "animalId",
                name: "name",
                diet: .herbivorous,
                categoryId: "categoryId"
              )
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == TreeDictionary(
        Self.state.animals.data.values + [
          Animal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == ["id" : .success]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test func dataPersistentSessionDidAddAnimalFailure() throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didAddAnimal(
            id: "id",
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == ["id" : .failure(error: "error")]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidUpdateAnimalSuccess(animal: Animal) throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didUpdateAnimal(
            animalId: animal.id,
            result: .success(
              animal: Animal(
                animalId: animal.id,
                name: "name",
                diet: .herbivorous,
                categoryId: "categoryId"
              )
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == {
        var state = Self.state
        state.animals.data[animal.id] = Animal(
          animalId: animal.id,
          name: "name",
          diet: .herbivorous,
          categoryId: "categoryId"
        )
        return state.animals.data
      }()
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == [animal.id : .success]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidUpdateAnimalFailure(animal: Animal) throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didUpdateAnimal(
            animalId: animal.id,
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == [animal.id : .failure(error: "error")]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidUpdateAnimalSuccessThrows(animal: Animal) {
    var state = Self.state
    state.animals.data[animal.id] = nil
    #expect {
      let _ = try AnimalsReducer.reduce(
        state: state,
        action: .data(
          .persistentSession(
            .didUpdateAnimal(
              animalId: animal.id,
              result: .success(
                animal: Animal(
                  animalId: animal.id,
                  name: "name",
                  diet: .herbivorous,
                  categoryId: "categoryId"
                )
              )
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? AnimalsReducer.Error
      )
      return error.code == .animalNotFound
    }
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidUpdateAnimalFailureThrows(animal: Animal) {
    var state = Self.state
    state.animals.data[animal.id] = nil
    #expect {
      let _ = try AnimalsReducer.reduce(
        state: state,
        action: .data(
          .persistentSession(
            .didUpdateAnimal(
              animalId: animal.id,
              result: .failure(
                error: "error"
              )
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? AnimalsReducer.Error
      )
      return error.code == .animalNotFound
    }
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidDeleteAnimalSuccess(animal: Animal) throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didDeleteAnimal(
            animalId: animal.id,
            result: .success(
              animal: Animal(
                animalId: animal.id,
                name: "name",
                diet: .herbivorous,
                categoryId: "categoryId"
              )
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == {
        var state = Self.state
        state.animals.data[animal.id] = nil
        return state.animals.data
      }()
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == [animal.id : .success]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidDeleteAnimalFailure(animal: Animal) throws {
    let state = try AnimalsReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .didDeleteAnimal(
            animalId: animal.id,
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    #expect(
      state.animals.data == Self.state.animals.data
    )
    #expect(
      state.animals.status == nil
    )
    #expect(
      state.animals.queue == [animal.id : .failure(error: "error")]
    )
    #expect(
      state.categories == Self.state.categories
    )
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidDeleteAnimalSuccessThrows(animal: Animal) {
    var state = Self.state
    state.animals.data[animal.id] = nil
    #expect {
      let _ = try AnimalsReducer.reduce(
        state: state,
        action: .data(
          .persistentSession(
            .didDeleteAnimal(
              animalId: animal.id,
              result: .success(
                animal: Animal(
                  animalId: animal.id,
                  name: "name",
                  diet: .herbivorous,
                  categoryId: "categoryId"
                )
              )
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? AnimalsReducer.Error
      )
      return error.code == .animalNotFound
    }
  }
}

extension AnimalsReducerTests {
  @Test(arguments: Self.state.animals.data.values) func dataPersistentSessionDidDeleteAnimalFailureThrows(animal: Animal) {
    var state = Self.state
    state.animals.data[animal.id] = nil
    #expect {
      let _ = try AnimalsReducer.reduce(
        state: state,
        action: .data(
          .persistentSession(
            .didUpdateAnimal(
              animalId: animal.id,
              result: .failure(
                error: "error"
              )
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? AnimalsReducer.Error
      )
      return error.code == .animalNotFound
    }
  }
}
