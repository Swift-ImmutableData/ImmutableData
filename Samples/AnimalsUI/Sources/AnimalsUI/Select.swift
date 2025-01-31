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
import ImmutableData
import ImmutableUI
import SwiftUI

extension ImmutableUI.DependencySelector {
  init(select: @escaping @Sendable (State) -> Dependency) where Dependency : Equatable {
    self.init(select: select, didChange: { $0 != $1 })
  }
}

extension ImmutableUI.OutputSelector {
  init(select: @escaping @Sendable (State) -> Output) where Output : Equatable {
    self.init(select: select, didChange: { $0 != $1 })
  }
}

extension ImmutableUI.Selector {
  init(
    id: some Hashable,
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat @escaping @Sendable (Store.State) -> each Dependency,
    outputSelector: @escaping @Sendable (Store.State) -> Output
  ) where Store == ImmutableData.Store<AnimalsState, AnimalsAction>, repeat each Dependency : Equatable, Output : Equatable {
    self.init(
      id: id,
      label: label,
      filter: isIncluded,
      dependencySelector: repeat DependencySelector(select: each dependencySelector),
      outputSelector: OutputSelector(select: outputSelector)
    )
  }
}

extension ImmutableUI.Selector {
  init(
    label: String? = nil,
    filter isIncluded: (@Sendable (Store.State, Store.Action) -> Bool)? = nil,
    dependencySelector: repeat @escaping @Sendable (Store.State) -> each Dependency,
    outputSelector: @escaping @Sendable (Store.State) -> Output
  ) where Store == ImmutableData.Store<AnimalsState, AnimalsAction>, repeat each Dependency : Equatable, Output : Equatable {
    self.init(
      label: label,
      filter: isIncluded,
      dependencySelector: repeat DependencySelector(select: each dependencySelector),
      outputSelector: OutputSelector(select: outputSelector)
    )
  }
}

@MainActor @propertyWrapper struct SelectCategoriesValues: DynamicProperty {
  @ImmutableUI.Selector(
    label: "SelectCategoriesValues",
    filter: AnimalsFilter.filterCategories(),
    dependencySelector: AnimalsState.selectCategories(),
    outputSelector: AnimalsState.selectCategoriesValues(sort: \AnimalsData.Category.name)
  ) var wrappedValue
  
  init() {
    
  }
}

@MainActor @propertyWrapper struct SelectCategoriesStatus: DynamicProperty {
  @ImmutableUI.Selector(
    label: "SelectCategoriesStatus",
    outputSelector: AnimalsState.selectCategoriesStatus()
  ) var wrappedValue: Status?
  
  init() {
    
  }
}

@MainActor @propertyWrapper struct SelectCategory: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<AnimalsState, AnimalsAction>, AnimalsData.Category?> var wrappedValue: AnimalsData.Category?
  
  init(categoryId: AnimalsData.Category.ID?) {
    self._wrappedValue = ImmutableUI.Selector(
      id: categoryId,
      label: "SelectCategory(categoryId: \(categoryId ?? "nil"))",
      outputSelector: AnimalsState.selectCategory(categoryId: categoryId)
    )
  }
  
  init(animalId: Animal.ID?) {
    self._wrappedValue = ImmutableUI.Selector(
      id: animalId,
      label: "SelectCategory(animalId: \(animalId ?? "nil"))",
      outputSelector: AnimalsState.selectCategory(animalId: animalId)
    )
  }
}

@MainActor @propertyWrapper struct SelectAnimalsValues: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<AnimalsState, AnimalsAction>, TreeDictionary<Animal.ID, Animal>, Array<Animal>> var wrappedValue: Array<Animal>
  
  init(categoryId: AnimalsData.Category.ID?) {
    self._wrappedValue = ImmutableUI.Selector(
      id: categoryId,
      label: "SelectAnimalsValues(categoryId: \(categoryId ?? "nil"))",
      filter: AnimalsFilter.filterAnimals(categoryId: categoryId),
      dependencySelector: AnimalsState.selectAnimals(categoryId: categoryId),
      outputSelector: AnimalsState.selectAnimalsValues(
        categoryId: categoryId,
        sort: \Animal.name
      )
    )
  }
}

@MainActor @propertyWrapper struct SelectAnimalsStatus: DynamicProperty {
  @ImmutableUI.Selector(
    label: "SelectAnimalsStatus",
    outputSelector: AnimalsState.selectAnimalsStatus()
  ) var wrappedValue: Status?
  
  init() {
    
  }
}

@MainActor @propertyWrapper struct SelectAnimal: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<AnimalsState, AnimalsAction>, Animal?> var wrappedValue: Animal?
  
  init(animalId: Animal.ID?) {
    self._wrappedValue = ImmutableUI.Selector(
      id: animalId,
      label: "SelectAnimal(animalId: \(animalId ?? "nil"))",
      outputSelector: AnimalsState.selectAnimal(animalId: animalId)
    )
  }
}

@MainActor @propertyWrapper struct SelectAnimalStatus: DynamicProperty {
  @ImmutableUI.Selector<ImmutableData.Store<AnimalsState, AnimalsAction>, Status?> var wrappedValue: Status?
  
  init(animalId: Animal.ID?) {
    self._wrappedValue = ImmutableUI.Selector(
      id: animalId,
      label: "SelectAnimalStatus(animalId: \(animalId ?? "nil"))",
      outputSelector: AnimalsState.selectAnimalStatus(animalId: animalId)
    )
  }
}
