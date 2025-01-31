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

@MainActor struct AnimalEditor {
  @State private var id: Animal.ID
  @Binding private var isPresented: Bool
  
  init(
    id: Animal.ID?,
    isPresented: Binding<Bool>
  ) {
    self._id = State(initialValue: id ?? UUID().uuidString)
    self._isPresented = isPresented
  }
}

extension AnimalEditor: View {
  var body: some View {
    let _ = Self.debugPrint()
    Container(
      id: self.id,
      isPresented: self.$isPresented
    )
  }
}

extension AnimalEditor {
  @MainActor fileprivate struct Container {
    @SelectAnimal private var animal: Animal?
    @SelectAnimalStatus private var status: Status?
    @SelectCategoriesValues private var categories: Array<AnimalsData.Category>
    
    private let id: Animal.ID
    @Binding private var isPresented: Bool
    
    @Dispatch private var dispatch
    
    init(
      id: Animal.ID,
      isPresented: Binding<Bool>
    ) {
      self._animal = SelectAnimal(animalId: id)
      self._status = SelectAnimalStatus(animalId: id)
      self._categories = SelectCategoriesValues()
      
      self.id = id
      self._isPresented = isPresented
    }
  }
}

extension AnimalEditor.Container {
  private func onTapAddAnimalButton(data: AnimalEditor.Presenter.AddAnimalData) {
    do {
      try self.dispatch(
        .ui(
          .animalEditor(
            .onTapAddAnimalButton(
              id: data.id,
              name: data.name,
              diet: data.diet,
              categoryId: data.categoryId
            )
          )
        )
      )
    } catch {
      print(error)
    }
  }
}

extension AnimalEditor.Container {
  private func onTapUpdateAnimalButton(data: AnimalEditor.Presenter.UpdateAnimalData) {
    do {
      try self.dispatch(
        .ui(
          .animalEditor(
            .onTapUpdateAnimalButton(
              animalId: data.animalId,
              name: data.name,
              diet: data.diet,
              categoryId: data.categoryId
            )
          )
        )
      )
    } catch {
      print(error)
    }
  }
}

extension AnimalEditor.Container: View {
  var body: some View {
    let _ = Self.debugPrint()
    AnimalEditor.Presenter(
      animal: self.animal,
      status: self.status,
      categories: self.categories,
      id: self.id,
      isPresented: self.$isPresented,
      onTapAddAnimalButton: self.onTapAddAnimalButton,
      onTapUpdateAnimalButton: self.onTapUpdateAnimalButton
    )
  }
}

extension AnimalEditor {
  @MainActor fileprivate struct Presenter {
    @State private var name: String
    @State private var diet: Animal.Diet?
    @State private var categoryId: AnimalsData.Category.ID?
    
    private let animal: Animal?
    private let status: Status?
    private let categories: Array<AnimalsData.Category>
    private let id: Animal.ID
    @Binding private var isPresented: Bool
    private let onTapAddAnimalButton: (AddAnimalData) -> Void
    private let onTapUpdateAnimalButton: (UpdateAnimalData) -> Void
    
    init(
      animal: Animal?,
      status: Status?,
      categories: Array<AnimalsData.Category>,
      id: Animal.ID,
      isPresented: Binding<Bool>,
      onTapAddAnimalButton: @escaping (AddAnimalData) -> Void,
      onTapUpdateAnimalButton: @escaping (UpdateAnimalData) -> Void
    ) {
      self._name = State(initialValue: animal?.name ?? "")
      self._diet = State(initialValue: animal?.diet)
      self._categoryId = State(initialValue: animal?.categoryId)
      
      self.animal = animal
      self.status = status
      self.categories = categories
      self._isPresented = isPresented
      self.id = id
      self.onTapAddAnimalButton = onTapAddAnimalButton
      self.onTapUpdateAnimalButton = onTapUpdateAnimalButton
    }
  }
}

extension AnimalEditor.Presenter {
  struct AddAnimalData: Hashable, Sendable {
    let id: Animal.ID
    let name: String
    let diet: Animal.Diet
    let categoryId: AnimalsData.Category.ID
  }
}

extension AnimalEditor.Presenter {
  struct UpdateAnimalData: Hashable, Sendable {
    let animalId: Animal.ID
    let name: String
    let diet: Animal.Diet
    let categoryId: AnimalsData.Category.ID
  }
}

extension AnimalEditor.Presenter {
  private var form: some View {
    Form {
      TextField("Name", text: self.$name)
      Picker("Category", selection: self.$categoryId) {
        Text("Select a category").tag(nil as String?)
        ForEach(self.categories) { category in
          Text(category.name).tag(category.categoryId as String?)
        }
      }
      Picker("Diet", selection: self.$diet) {
        Text("Select a diet").tag(nil as Animal.Diet?)
        ForEach(Animal.Diet.allCases, id: \.self) { diet in
          Text(diet.rawValue).tag(diet as Animal.Diet?)
        }
      }
    }
  }
}

extension AnimalEditor.Presenter {
  private var cancelButton: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button("Cancel", role: .cancel) {
        self.isPresented = false
      }
    }
  }
}

extension AnimalEditor.Presenter {
  private var saveButton: some ToolbarContent {
    ToolbarItem(placement: .confirmationAction) {
      Button("Save") {
        if let diet = self.diet,
           let categoryId = self.categoryId {
          if self.animal != nil {
            self.onTapUpdateAnimalButton(
              UpdateAnimalData(
                animalId: self.id,
                name: self.name,
                diet: diet,
                categoryId: categoryId
              )
            )
          } else {
            self.onTapAddAnimalButton(
              AddAnimalData(
                id: self.id,
                name: self.name,
                diet: diet,
                categoryId: categoryId
              )
            )
          }
        }
      }
      .disabled(self.isSaveDisabled)
    }
  }
}

extension AnimalEditor.Presenter {
  private var isSaveDisabled: Bool {
    if self.status == .waiting {
      return true
    }
    if self.name.isEmpty {
      return true
    }
    if self.diet == nil {
      return true
    }
    if self.categoryId == nil {
      return true
    }
    return false
  }
}

extension AnimalEditor.Presenter: View {
  var body: some View {
    let _ = Self.debugPrint()
    self.form
      .navigationTitle(self.animal != nil ? "Edit Animal" : "Add Animal")
      .onChange(of: self.status) {
        if self.status == .success {
          self.isPresented = false
        }
      }
      .toolbar {
        self.cancelButton
        self.saveButton
      }
      .padding()
  }
}

#Preview {
  @Previewable @State var isPresented: Bool = true
  NavigationStack {
    PreviewStore {
      AnimalEditor(
        id: Animal.kangaroo.animalId,
        isPresented: $isPresented
      )
    }
  }
}

#Preview {
  @Previewable @State var isPresented: Bool = true
  NavigationStack {
    PreviewStore {
      AnimalEditor(
        id: nil,
        isPresented: $isPresented
      )
    }
  }
}

#Preview {
  @Previewable @State var isPresented: Bool = true
  NavigationStack {
    AnimalEditor.Presenter(
      animal: .kangaroo,
      status: nil,
      categories: [
        .amphibian,
        .bird,
        .fish,
        .invertebrate,
        .mammal,
        .reptile,
      ],
      id: Animal.kangaroo.animalId,
      isPresented: $isPresented,
      onTapAddAnimalButton: { data in
        print("onTapAddAnimalButton: \(data)")
      },
      onTapUpdateAnimalButton: { data in
        print("onTapUpdateAnimalButton: \(data)")
      }
    )
  }
}

#Preview {
  @Previewable @State var isPresented: Bool = true
  NavigationStack {
    AnimalEditor.Presenter(
      animal: nil,
      status: nil,
      categories: [
        .amphibian,
        .bird,
        .fish,
        .invertebrate,
        .mammal,
        .reptile,
      ],
      id: "1234",
      isPresented: $isPresented,
      onTapAddAnimalButton: { data in
        print("onTapAddAnimalButton: \(data)")
      },
      onTapUpdateAnimalButton: { data in
        print("onTapUpdateAnimalButton: \(data)")
      }
    )
  }
}
