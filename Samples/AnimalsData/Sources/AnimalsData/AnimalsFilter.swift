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

public enum AnimalsFilter {
  
}

extension AnimalsFilter {
  public static func filterCategories() -> @Sendable (AnimalsState, AnimalsAction) -> Bool {
    { oldState, action in
      switch action {
      case .data(.persistentSession(.didFetchCategories(result: .success))):
        return true
      case .data(.persistentSession(.didReloadSampleData(result: .success))):
        return true
      default:
        return false
      }
    }
  }
}

extension AnimalsFilter {
  public static func filterAnimals(categoryId: Category.ID?) -> @Sendable (AnimalsState, AnimalsAction) -> Bool {
    { oldState, action in
      switch action {
      case .data(.persistentSession(.didFetchAnimals(result: .success))):
        return true
      case .data(.persistentSession(.didReloadSampleData(result: .success))):
        return true
      case .data(.persistentSession(.didAddAnimal(id: _, result: .success(animal: let animal)))):
        return animal.categoryId == categoryId
      case .data(.persistentSession(.didDeleteAnimal(animalId: _, result: .success(animal: let animal)))):
        return animal.categoryId == categoryId
      case .data(.persistentSession(.didUpdateAnimal(animalId: _, result: .success(animal: let animal)))):
        return animal.categoryId == categoryId || oldState.animals.data[animal.animalId]?.categoryId == categoryId
      default:
        return false
      }
    }
  }
}
