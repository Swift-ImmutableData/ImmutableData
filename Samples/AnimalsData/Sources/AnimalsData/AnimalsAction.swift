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

public enum AnimalsAction: Hashable, Sendable {
  case ui(_ action: UI)
  case data(_ action: Data)
}

extension AnimalsAction {
  public enum UI: Hashable, Sendable {
    case categoryList(_ action: CategoryList)
    case animalList(_ action: AnimalList)
    case animalDetail(_ action: AnimalDetail)
    case animalEditor(_ action: AnimalEditor)
  }
}

extension AnimalsAction.UI {
  public enum CategoryList: Hashable, Sendable {
    case onAppear
    case onTapReloadSampleDataButton
  }
}

extension AnimalsAction.UI {
  public enum AnimalList: Hashable, Sendable {
    case onAppear
    case onTapDeleteSelectedAnimalButton(animalId: Animal.ID)
  }
}

extension AnimalsAction.UI {
  public enum AnimalDetail: Hashable, Sendable {
    case onTapDeleteSelectedAnimalButton(animalId: Animal.ID)
  }
}

extension AnimalsAction.UI {
  public enum AnimalEditor: Hashable, Sendable {
    case onTapAddAnimalButton(
      id: Animal.ID,
      name: String,
      diet: Animal.Diet,
      categoryId: Category.ID
    )
    case onTapUpdateAnimalButton(
      animalId: Animal.ID,
      name: String,
      diet: Animal.Diet,
      categoryId: Category.ID
    )
  }
}

extension AnimalsAction {
  public enum Data: Hashable, Sendable {
    case persistentSession(_ action: PersistentSession)
  }
}

extension AnimalsAction.Data {
  public enum PersistentSession: Hashable, Sendable {
    case didFetchCategories(result: FetchCategoriesResult)
    case didFetchAnimals(result: FetchAnimalsResult)
    case didReloadSampleData(result: ReloadSampleDataResult)
    case didAddAnimal(
      id: Animal.ID,
      result: AddAnimalResult
    )
    case didUpdateAnimal(
      animalId: Animal.ID,
      result: UpdateAnimalResult
    )
    case didDeleteAnimal(
      animalId: Animal.ID,
      result: DeleteAnimalResult
    )
  }
}

extension AnimalsAction.Data.PersistentSession {
  public enum FetchCategoriesResult: Hashable, Sendable {
    case success(categories: Array<Category>)
    case failure(error: String)
  }
}

extension AnimalsAction.Data.PersistentSession {
  public enum FetchAnimalsResult: Hashable, Sendable {
    case success(animals: Array<Animal>)
    case failure(error: String)
  }
}

extension AnimalsAction.Data.PersistentSession {
  public enum ReloadSampleDataResult: Hashable, Sendable {
    case success(
      animals: Array<Animal>,
      categories: Array<Category>
    )
    case failure(error: String)
  }
}

extension AnimalsAction.Data.PersistentSession {
  public enum AddAnimalResult: Hashable, Sendable {
    case success(animal: Animal)
    case failure(error: String)
  }
}

extension AnimalsAction.Data.PersistentSession {
  public enum UpdateAnimalResult: Hashable, Sendable {
    case success(animal: Animal)
    case failure(error: String)
  }
}

extension AnimalsAction.Data.PersistentSession {
  public enum DeleteAnimalResult: Hashable, Sendable {
    case success(animal: Animal)
    case failure(error: String)
  }
}
