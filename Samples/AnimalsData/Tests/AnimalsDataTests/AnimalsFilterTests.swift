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

@Suite final actor AnimalsFilterTests {
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

extension AnimalsFilterTests {
  private static var filterAnimalsIncludedArguments: Array<(category: Category, action: AnimalsAction)> {
    var array = Array<(category: Category, action: AnimalsAction)>()
    for category in Self.state.categories.data.values {
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didAddAnimal(
                id: "id",
                result: .success(
                  animal: Animal(
                    animalId: "animalId",
                    name: "name",
                    diet: .herbivorous,
                    categoryId: category.id
                  )
                )
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didUpdateAnimal(
                animalId: "animalId",
                result: .success(
                  animal: Animal(
                    animalId: "animalId",
                    name: "name",
                    diet: .herbivorous,
                    categoryId: category.id
                  )
                )
              )
            )
          )
        )
      )
      for animal in Self.state.animals.data.values {
        if animal.categoryId == category.id {
          array.append(
            (
              category: category,
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
          )
        }
      }
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didDeleteAnimal(
                animalId: "animalId",
                result: .success(
                  animal: Animal(
                    animalId: "animalId",
                    name: "name",
                    diet: .herbivorous,
                    categoryId: category.id
                  )
                )
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didFetchAnimals(
                result: .success(
                  animals: []
                )
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didReloadSampleData(
                result: .success(
                  animals: [],
                  categories: []
                )
              )
            )
          )
        )
      )
    }
    return array
  }
}

extension AnimalsFilterTests {
  private static var filterAnimalsNotIncludedArguments: Array<(category: Category, action: AnimalsAction)> {
    var array = Array<(category: Category, action: AnimalsAction)>()
    for category in Self.state.categories.data.values {
      array.append(
        (
          category: category,
          action: .ui(
            .categoryList(
              .onAppear
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .ui(
            .categoryList(
              .onTapReloadSampleDataButton
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .ui(
            .animalList(
              .onAppear
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .ui(
            .animalList(
              .onTapDeleteSelectedAnimalButton(
                animalId: "animalId"
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .ui(
            .animalDetail(
              .onTapDeleteSelectedAnimalButton(
                animalId: "animalId"
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
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
      )
      array.append(
        (
          category: category,
          action: .ui(
            .animalEditor(
              .onTapUpdateAnimalButton(
                animalId: "animalId",
                name: "name",
                diet: .herbivorous,
                categoryId: "categoryId"
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didFetchCategories(
                result: .success(
                  categories: []
                )
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
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
      )
      array.append(
        (
          category: category,
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
      )
      array.append(
        (
          category: category,
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
      )
      array.append(
        (
          category: category,
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
      )
      array.append(
        (
          category: category,
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
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didUpdateAnimal(
                animalId: "animalId",
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
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didUpdateAnimal(
                animalId: "animalId",
                result: .failure(
                  error: "error"
                )
              )
            )
          )
        )
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didDeleteAnimal(
                animalId: "animalId",
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
      )
      array.append(
        (
          category: category,
          action: .data(
            .persistentSession(
              .didDeleteAnimal(
                animalId: "animalId",
                result: .failure(
                  error: "error"
                )
              )
            )
          )
        )
      )
    }
    return array
  }
}

extension AnimalsFilterTests {
  private static var filterCategoriesIncludedArguments: Array<AnimalsAction> {
    var array = Array<AnimalsAction>()
    array.append(
      .data(
        .persistentSession(
          .didFetchCategories(
            result: .success(
              categories: []
            )
          )
        )
      )
    )
    array.append(
      .data(
        .persistentSession(
          .didReloadSampleData(
            result: .success(
              animals: [],
              categories: []
            )
          )
        )
      )
    )
    return array
  }
}

extension AnimalsFilterTests {
  private static var filterCategoriesNotIncludedArguments: Array<AnimalsAction> {
    var array = Array<AnimalsAction>()
    array.append(
      .ui(
        .categoryList(
          .onAppear
        )
      )
    )
    array.append(
      .ui(
        .categoryList(
          .onTapReloadSampleDataButton
        )
      )
    )
    array.append(
      .ui(
        .animalList(
          .onAppear
        )
      )
    )
    array.append(
      .ui(
        .animalList(
          .onTapDeleteSelectedAnimalButton(
            animalId: "animalId"
          )
        )
      )
    )
    array.append(
      .ui(
        .animalDetail(
          .onTapDeleteSelectedAnimalButton(
            animalId: "animalId"
          )
        )
      )
    )
    array.append(
      .ui(
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
    array.append(
      .ui(
        .animalEditor(
          .onTapUpdateAnimalButton(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        )
      )
    )
    array.append(
      .data(
        .persistentSession(
          .didFetchCategories(
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    array.append(
      .data(
        .persistentSession(
          .didFetchAnimals(
            result: .success(
              animals: []
            )
          )
        )
      )
    )
    array.append(
      .data(
        .persistentSession(
          .didFetchAnimals(
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    array.append(
      .data(
        .persistentSession(
          .didReloadSampleData(
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    array.append(
      .data(
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
    array.append(
      .data(
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
    array.append(
      .data(
        .persistentSession(
          .didUpdateAnimal(
            animalId: "animalId",
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
    array.append(
      .data(
        .persistentSession(
          .didUpdateAnimal(
            animalId: "animalId",
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    array.append(
      .data(
        .persistentSession(
          .didDeleteAnimal(
            animalId: "animalId",
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
    array.append(
      .data(
        .persistentSession(
          .didDeleteAnimal(
            animalId: "animalId",
            result: .failure(
              error: "error"
            )
          )
        )
      )
    )
    return array
  }
}

extension AnimalsFilterTests {
  @Test(arguments: AnimalsFilterTests.filterAnimalsIncludedArguments) func filterAnimalsIncluded(category: Category, action: AnimalsAction) {
    let isIncluded = AnimalsFilter.filterAnimals(categoryId: category.id)(Self.state, action)
    #expect(isIncluded)
  }
}

extension AnimalsFilterTests {
  @Test(arguments: AnimalsFilterTests.filterAnimalsNotIncludedArguments) func filterAnimalsNotIncluded(category: Category, action: AnimalsAction) {
    let isIncluded = AnimalsFilter.filterAnimals(categoryId: category.id)(Self.state, action)
    #expect(isIncluded == false)
  }
}

extension AnimalsFilterTests {
  @Test(arguments: AnimalsFilterTests.filterCategoriesIncludedArguments) func filterCategoriesIncluded(action: AnimalsAction) {
    let isIncluded = AnimalsFilter.filterCategories()(Self.state, action)
    #expect(isIncluded)
  }
}

extension AnimalsFilterTests {
  @Test(arguments: AnimalsFilterTests.filterCategoriesNotIncludedArguments) func filterCategoriesNotIncluded(action: AnimalsAction) {
    let isIncluded = AnimalsFilter.filterCategories()(Self.state, action)
    #expect(isIncluded == false)
  }
}
