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
import SwiftUI

@MainActor struct AnimalList {
  private let selectedCategoryId: AnimalsData.Category.ID?
  @Binding private var selectedAnimalId: Animal.ID?
  
  init(
    selectedCategoryId: AnimalsData.Category.ID?,
    selectedAnimalId: Binding<Animal.ID?>
  ) {
    self.selectedCategoryId = selectedCategoryId
    self._selectedAnimalId = selectedAnimalId
  }
}

extension AnimalList : View {
  var body: some View {
    Container(
      selectedCategoryId: self.selectedCategoryId,
      selectedAnimalId: self.$selectedAnimalId
    )
  }
}

extension AnimalList {
  @MainActor fileprivate struct Container {
    @SelectAnimalsValues private var animals: Array<Animal>
    @SelectCategory private var category: AnimalsData.Category?
    @SelectAnimalsStatus private var status: Status?
    
    @Binding private var selectedAnimalId: Animal.ID?
    
    @Dispatch private var dispatch
    
    init(
      selectedCategoryId: AnimalsData.Category.ID?,
      selectedAnimalId: Binding<Animal.ID?>
    ) {
      self._animals = SelectAnimalsValues(categoryId: selectedCategoryId)
      self._category = SelectCategory(categoryId: selectedCategoryId)
      self._status = SelectAnimalsStatus()
      
      self._selectedAnimalId = selectedAnimalId
    }
  }
}

extension AnimalList.Container {
  private func onAppear() {
    do {
      try self.dispatch(
        .ui(
          .animalList(
            .onAppear
          )
        )
      )
    } catch {
      print(error)
    }
  }
}

extension AnimalList.Container {
  private func onTapDeleteSelectedAnimalButton(animal: Animal) {
    do {
      try self.dispatch(
        .ui(
          .animalList(
            .onTapDeleteSelectedAnimalButton(
              animalId: animal.id
            )
          )
        )
      )
    } catch {
      print(error)
    }
  }
}

extension AnimalList.Container: View {
  var body: some View {
    let _ = Self.debugPrint()
    AnimalList.Presenter(
      animals: self.animals,
      category: self.category,
      status: self.status,
      selectedAnimalId: self.$selectedAnimalId,
      onAppear: self.onAppear,
      onTapDeleteSelectedAnimalButton: self.onTapDeleteSelectedAnimalButton
    )
  }
}

extension AnimalList {
  @MainActor fileprivate struct Presenter {
    @State private var isSheetPresented = false
    
    private let animals: Array<Animal>
    private let category: AnimalsData.Category?
    private let status: Status?
    @Binding private var selectedAnimalId: Animal.ID?
    private let onAppear: () -> Void
    private let onTapDeleteSelectedAnimalButton: (Animal) -> Void
    
    init(
      animals: Array<Animal>,
      category: AnimalsData.Category?,
      status: Status?,
      selectedAnimalId: Binding<Animal.ID?>,
      onAppear: @escaping () -> Void,
      onTapDeleteSelectedAnimalButton: @escaping (Animal) -> Void
    ) {
      self.animals = animals
      self.category = category
      self.status = status
      self._selectedAnimalId = selectedAnimalId
      self.onAppear = onAppear
      self.onTapDeleteSelectedAnimalButton = onTapDeleteSelectedAnimalButton
    }
  }
}

extension AnimalList.Presenter {
  var list: some View {
    List(selection: self.$selectedAnimalId) {
      ForEach(self.animals) { animal in
        NavigationLink(animal.name, value: animal.id)
          .deleteDisabled(false)
      }
      .onDelete { indexSet in
        for index in indexSet {
          let animal = self.animals[index]
          self.onTapDeleteSelectedAnimalButton(animal)
        }
      }
    }
  }
}

extension AnimalList.Presenter {
  var addButton: some View {
    Button { self.isSheetPresented = true } label: {
      Label("Add an animal", systemImage: "plus")
    }
    .disabled(self.status == .waiting)
  }
}

extension AnimalList.Presenter: View {
  var body: some View {
    let _ = Self.debugPrint()
    if let category = self.category {
      self.list
        .navigationTitle(category.name)
        .onAppear {
          self.onAppear()
        }
        .overlay {
          if self.animals.isEmpty {
            ContentUnavailableView {
              Label("No animals in this category", systemImage: "pawprint")
            } description: {
              self.addButton
            }
          }
        }
        .sheet(isPresented: self.$isSheetPresented) {
          NavigationStack {
            AnimalEditor(
              id: nil,
              isPresented: self.$isSheetPresented
            )
          }
        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            self.addButton
          }
        }
    } else {
      ContentUnavailableView("Select a category", systemImage: "sidebar.left")
    }
  }
}

#Preview {
  @Previewable @State var selectedAnimal: Animal.ID?
  NavigationStack {
    PreviewStore {
      AnimalList(
        selectedCategoryId: Category.mammal.id,
        selectedAnimalId: $selectedAnimal
      )
    }
  }
}

#Preview {
  @Previewable @State var selectedAnimalId: Animal.ID?
  NavigationStack {
    AnimalList.Presenter(
      animals: [
        Animal.cat,
        Animal.dog,
        Animal.kangaroo,
        Animal.gibbon,
      ],
      category: .mammal,
      status: nil,
      selectedAnimalId: $selectedAnimalId,
      onAppear: {
        print("onAppear")
      },
      onTapDeleteSelectedAnimalButton: { animal in
        print("onTapDeleteSelectedAnimalButton: \(animal)")
      }
    )
  }
}
