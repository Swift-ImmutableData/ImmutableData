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
import Testing

@Suite final actor AnimalsStateTests {
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

extension AnimalsStateTests {
  @Test func selectCategories() {
    let state = Self.state
    #expect(AnimalsState.selectCategories()(state) == state.categories.data)
  }
}

extension AnimalsStateTests {
  @Test(
    arguments: AnimalsDataTests.product(
      [\AnimalsData.Category.id, \AnimalsData.Category.name],
      [SortOrder.forward, SortOrder.reverse]
    )
  ) func selectCategoriesValues(
    partialKeyPath: PartialKeyPath<AnimalsData.Category> & Sendable,
    order: SortOrder
  ) {
    func test<Value>(
      partialKeyPath: PartialKeyPath<AnimalsData.Category> & Sendable,
      valueType: Value.Type,
      order: SortOrder
    ) where Value : Comparable {
      let keyPath = partialKeyPath as! KeyPath<AnimalsData.Category, Value> & Sendable
      let state = Self.state
      let values = AnimalsState.selectCategoriesValues(
        sort: keyPath,
        order: order
      )(state)
      #expect(values == state.categories.data.values.sorted(using: SortDescriptor(keyPath, order: order)))
    }
    let valueType = type(of: partialKeyPath).valueType as! any Comparable.Type
    test(
      partialKeyPath: partialKeyPath,
      valueType: valueType,
      order: order
    )
  }
}

extension AnimalsStateTests {
  @Test func selectCategoriesStatus() {
    var state = Self.state
    #expect(AnimalsState.selectCategoriesStatus()(state) == nil)
    
    state.categories.status = .empty
    #expect(AnimalsState.selectCategoriesStatus()(state) == .empty)
    
    state.categories.status = .waiting
    #expect(AnimalsState.selectCategoriesStatus()(state) == .waiting)
    
    state.categories.status = .success
    #expect(AnimalsState.selectCategoriesStatus()(state) == .success)
    
    state.categories.status = .failure(error: "error")
    #expect(AnimalsState.selectCategoriesStatus()(state) == .failure(error: "error"))
  }
}

extension AnimalsStateTests {
  @Test(arguments: Self.state.categories.data.values) func selectCategory(category: AnimalsData.Category) {
    let state = Self.state
    #expect(AnimalsState.selectCategory(categoryId: category.id)(state) == category)
  }
}

extension AnimalsStateTests {
  @Test(arguments: Self.state.animals.data.values) func selectCategory(animal: Animal) {
    let state = Self.state
    let category = state.categories.data[animal.categoryId]
    #expect(AnimalsState.selectCategory(animalId: animal.id)(state) == category)
  }
}

extension AnimalsStateTests {
  @Test(arguments: Self.state.categories.data.values) func selectAnimals(category: AnimalsData.Category) {
    let state = Self.state
    let values = AnimalsState.selectAnimals(categoryId: category.id)(state)
    #expect(values == state.animals.data.filter { element in
      element.value.categoryId == category.id
    })
  }
}

extension AnimalsStateTests {
  @Test(
    arguments: AnimalsDataTests.product(
      Self.state.categories.data.values,
      [\Animal.id, \Animal.name, \Animal.categoryId],
      [SortOrder.forward, SortOrder.reverse]
    )
  ) func selectAnimalsValues(
    category: AnimalsData.Category,
    partialKeyPath: PartialKeyPath<Animal> & Sendable,
    order: SortOrder
  ) {
    func test<Value>(
      category: AnimalsData.Category,
      partialKeyPath: PartialKeyPath<Animal> & Sendable,
      valueType: Value.Type,
      order: SortOrder
    ) where Value : Comparable {
      let keyPath = partialKeyPath as! KeyPath<Animal, Value> & Sendable
      let state = Self.state
      let values = AnimalsState.selectAnimalsValues(
        categoryId: category.id,
        sort: keyPath,
        order: order
      )(state)
      #expect(values == state.animals.data.values.filter { animal in
        animal.categoryId == category.id
      }.sorted(using: SortDescriptor(keyPath, order: order)))
    }
    let valueType = type(of: partialKeyPath).valueType as! any Comparable.Type
    test(
      category: category,
      partialKeyPath: partialKeyPath,
      valueType: valueType,
      order: order
    )
  }
}

extension AnimalsStateTests {
  @Test func selectAnimalsStatus() {
    var state = Self.state
    #expect(AnimalsState.selectAnimalsStatus()(state) == nil)
    
    state.animals.status = .empty
    #expect(AnimalsState.selectAnimalsStatus()(state) == .empty)
    
    state.animals.status = .waiting
    #expect(AnimalsState.selectAnimalsStatus()(state) == .waiting)
    
    state.animals.status = .success
    #expect(AnimalsState.selectAnimalsStatus()(state) == .success)
    
    state.animals.status = .failure(error: "error")
    #expect(AnimalsState.selectAnimalsStatus()(state) == .failure(error: "error"))
  }
}

extension AnimalsStateTests {
  @Test(arguments: Self.state.animals.data.values) func selectAnimal(animal: Animal) {
    let state = Self.state
    #expect(AnimalsState.selectAnimal(animalId: animal.id)(state) == animal)
  }
}

extension AnimalsStateTests {
  @Test(arguments: Self.state.animals.data.values) func selectAnimalStatus(animal: Animal) {
    var state = Self.state
    #expect(AnimalsState.selectAnimalStatus(animalId: animal.id)(state) == nil)
    
    state.animals.queue[animal.id] = .empty
    #expect(AnimalsState.selectAnimalStatus(animalId: animal.id)(state) == .empty)
    
    state.animals.queue[animal.id] = .waiting
    #expect(AnimalsState.selectAnimalStatus(animalId: animal.id)(state) == .waiting)
    
    state.animals.queue[animal.id] = .success
    #expect(AnimalsState.selectAnimalStatus(animalId: animal.id)(state) == .success)
    
    state.animals.queue[animal.id] = .failure(error: "error")
    #expect(AnimalsState.selectAnimalStatus(animalId: animal.id)(state) == .failure(error: "error"))
  }
}
