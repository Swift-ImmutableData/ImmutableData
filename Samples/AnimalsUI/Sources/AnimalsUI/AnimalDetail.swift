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

@MainActor struct AnimalDetail {
  private let selectedAnimalId: Animal.ID?
  
  init(selectedAnimalId: Animal.ID?) {
    self.selectedAnimalId = selectedAnimalId
  }
}

extension AnimalDetail : View {
  var body: some View {
    let _ = Self.debugPrint()
    Container(selectedAnimalId: self.selectedAnimalId)
  }
}

extension AnimalDetail {
  @MainActor fileprivate struct Container {
    @SelectAnimal private var animal: Animal?
    @SelectCategory private var category: AnimalsData.Category?
    @SelectAnimalStatus private var status: Status?
    
    @Dispatch private var dispatch
    
    init(selectedAnimalId: Animal.ID?) {
      self._animal = SelectAnimal(animalId: selectedAnimalId)
      self._category = SelectCategory(animalId: selectedAnimalId)
      self._status = SelectAnimalStatus(animalId: selectedAnimalId)
    }
  }
}

extension AnimalDetail.Container {
  private func onTapDeleteSelectedAnimalButton(animal: Animal) {
    do {
      try self.dispatch(
        .ui(
          .animalDetail(
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

extension AnimalDetail.Container: View {
  var body: some View {
    let _ = Self.debugPrint()
    AnimalDetail.Presenter(
      animal: self.animal,
      category: self.category,
      status: self.status,
      onTapDeleteSelectedAnimalButton: self.onTapDeleteSelectedAnimalButton
    )
  }
}

extension AnimalDetail {
  @MainActor fileprivate struct Presenter {
    @State private var isAlertPresented = false
    @State private var isSheetPresented = false
    
    private let animal: Animal?
    private let category: AnimalsData.Category?
    private let status: Status?
    private let onTapDeleteSelectedAnimalButton: (Animal) -> Void
    
    init(
      animal: Animal?,
      category: AnimalsData.Category?,
      status: Status?,
      onTapDeleteSelectedAnimalButton: @escaping (Animal) -> Void
    ) {
      self.animal = animal
      self.category = category
      self.status = status
      self.onTapDeleteSelectedAnimalButton = onTapDeleteSelectedAnimalButton
    }
  }
}

extension AnimalDetail.Presenter: View {
  var body: some View {
    let _ = Self.debugPrint()
    if let animal = self.animal,
       let category = self.category {
      VStack {
        Text(animal.name)
          .font(.title)
          .padding()
        List {
          HStack {
            Text("Category")
            Spacer()
            Text(category.name)
          }
          HStack {
            Text("Diet")
            Spacer()
            Text(animal.diet.rawValue)
          }
        }
      }
      .alert("Delete \(animal.name)?", isPresented: self.$isAlertPresented) {
        Button("Yes, delete \(animal.name)", role: .destructive) {
          self.onTapDeleteSelectedAnimalButton(animal)
        }
      }
      .sheet(isPresented: self.$isSheetPresented) {
        NavigationStack {
          AnimalEditor(
            id: animal.id,
            isPresented: self.$isSheetPresented
          )
        }
      }
      .toolbar {
        Button { self.isSheetPresented = true } label: {
          Label("Edit \(animal.name)", systemImage: "pencil")
        }
        .disabled(self.status == .waiting)
        Button { self.isAlertPresented = true } label: {
          Label("Delete \(animal.name)", systemImage: "trash")
        }
        .disabled(self.status == .waiting)
      }
    } else {
      ContentUnavailableView("Select an animal", systemImage: "pawprint")
    }
  }
}

#Preview {
  NavigationStack {
    PreviewStore {
      AnimalDetail(selectedAnimalId: Animal.kangaroo.animalId)
    }
  }
}

#Preview {
  NavigationStack {
    PreviewStore {
      AnimalDetail(selectedAnimalId: nil)
    }
  }
}

#Preview {
  NavigationStack {
    AnimalDetail.Presenter(
      animal: .kangaroo,
      category: .mammal,
      status: nil,
      onTapDeleteSelectedAnimalButton: { animal in
        print("onTapDeleteSelectedAnimalButton: \(animal)")
      }
    )
  }
}

#Preview {
  NavigationStack {
    AnimalDetail.Presenter(
      animal: nil,
      category: nil,
      status: nil,
      onTapDeleteSelectedAnimalButton: { animal in
        print("onTapDeleteSelectedAnimalButton: \(animal)")
      }
    )
  }
}
