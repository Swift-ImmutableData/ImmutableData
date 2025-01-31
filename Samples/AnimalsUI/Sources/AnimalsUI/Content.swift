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

@MainActor public struct Content {
  @State private var selectedCategoryId: AnimalsData.Category.ID?
  @State private var selectedAnimalId: Animal.ID?
  
  public init() {
    
  }
}

extension Content: View {
  public var body: some View {
    let _ = Self.debugPrint()
    NavigationSplitView {
      CategoryList(selectedCategoryId: self.$selectedCategoryId)
    } content: {
      AnimalList(
        selectedCategoryId: self.selectedCategoryId,
        selectedAnimalId: self.$selectedAnimalId
      )
    } detail: {
      AnimalDetail(selectedAnimalId: self.selectedAnimalId)
    }
  }
}

#Preview {
  PreviewStore {
    Content()
  }
}
