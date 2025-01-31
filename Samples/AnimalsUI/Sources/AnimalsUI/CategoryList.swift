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

@MainActor struct CategoryList {
  @Binding private var selectedCategoryId: AnimalsData.Category.ID?
  
  init(selectedCategoryId: Binding<AnimalsData.Category.ID?>) {
    self._selectedCategoryId = selectedCategoryId
  }
}

extension CategoryList : View {
  var body: some View {
    let _ = CategoryList.debugPrint()
    Container(selectedCategoryId: self.$selectedCategoryId)
  }
}

extension CategoryList {
  @MainActor fileprivate struct Container {
    @SelectCategoriesValues private var categories: Array<AnimalsData.Category>
    @SelectCategoriesStatus private var status: Status?
    
    @Binding private var selectedCategoryId: AnimalsData.Category.ID?
    
    @Dispatch private var dispatch
    
    init(selectedCategoryId: Binding<AnimalsData.Category.ID?>) {
      self._categories = SelectCategoriesValues()
      self._status = SelectCategoriesStatus()
      
      self._selectedCategoryId = selectedCategoryId
    }
  }
}

extension CategoryList.Container {
  private func onAppear() {
    do {
      try self.dispatch(
        .ui(
          .categoryList(
            .onAppear
          )
        )
      )
    } catch {
      print(error)
    }
  }
}

extension CategoryList.Container {
  private func onReloadSampleData() {
    do {
      try self.dispatch(
        .ui(
          .categoryList(
            .onTapReloadSampleDataButton
          )
        )
      )
    } catch {
      print(error)
    }
  }
}

extension CategoryList.Container: View {
  var body: some View {
    let _ = Self.debugPrint()
    CategoryList.Presenter(
      categories: self.categories,
      status: self.status,
      selectedCategoryId: self.$selectedCategoryId,
      onAppear: self.onAppear,
      onReloadSampleData: self.onReloadSampleData
    )
  }
}

extension CategoryList {
  @MainActor fileprivate struct Presenter {
    @State private var isAlertPresented = false
    
    private let categories: Array<AnimalsData.Category>
    private let status: Status?
    @Binding private var selectedCategoryId: AnimalsData.Category.ID?
    private let onAppear: () -> Void
    private let onReloadSampleData: () -> Void
    
    init(
      categories: Array<AnimalsData.Category>,
      status: Status?,
      selectedCategoryId: Binding<AnimalsData.Category.ID?>,
      onAppear: @escaping () -> Void,
      onReloadSampleData: @escaping () -> Void
    ) {
      self.categories = categories
      self.status = status
      self._selectedCategoryId = selectedCategoryId
      self.onAppear = onAppear
      self.onReloadSampleData = onReloadSampleData
    }
  }
}

extension CategoryList.Presenter {
  var list: some View {
    List(selection: self.$selectedCategoryId) {
      Section("Categories") {
        ForEach(self.categories) { category in
          NavigationLink(category.name, value: category.id)
        }
      }
    }
  }
}

extension CategoryList.Presenter: View {
  var body: some View {
    let _ = Self.debugPrint()
    self.list
      .alert("Reload Sample Data?", isPresented: self.$isAlertPresented) {
        Button("Yes, reload sample data", role: .destructive) {
          self.onReloadSampleData()
        }
      } message: {
        Text("Reloading the sample data deletes all changes to the current data.")
      }
      .onAppear {
        self.onAppear()
      }
      .toolbar {
        Button { self.isAlertPresented = true } label: {
          Label("Reload sample data", systemImage: "arrow.clockwise")
        }
        .disabled(self.status == .waiting)
      }
  }
}

#Preview {
  @Previewable @State var selectedCategoryId: AnimalsData.Category.ID?
  NavigationStack {
    PreviewStore {
      CategoryList(selectedCategoryId: $selectedCategoryId)
    }
  }
}

#Preview {
  @Previewable @State var selectedCategoryId: AnimalsData.Category.ID?
  NavigationStack {
    CategoryList.Presenter(
      categories: [
        Category.amphibian,
        Category.bird,
        Category.fish,
        Category.invertebrate,
        Category.mammal,
        Category.reptile,
      ],
      status: nil,
      selectedCategoryId: $selectedCategoryId,
      onAppear: {
        print("onAppear")
      },
      onReloadSampleData: {
        print("onReloadSampleData")
      }
    )
  }
}
