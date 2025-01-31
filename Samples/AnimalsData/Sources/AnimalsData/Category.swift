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

import CowBox

@CowBox(init: .withPackage) public struct Category: Hashable, Codable, Sendable {
  public let categoryId: String
  public let name: String
}

extension Category: Identifiable {
  public var id: String {
    self.categoryId
  }
}

extension Category {
  public static var amphibian: Self {
    Self(
      categoryId: "Amphibian",
      name: "Amphibian"
    )
  }
  public static var bird: Self {
    Self(
      categoryId: "Bird",
      name: "Bird"
    )
  }
  public static var fish: Self {
    Self(
      categoryId: "Fish",
      name: "Fish"
    )
  }
  public static var invertebrate: Self {
    Self(
      categoryId: "Invertebrate",
      name: "Invertebrate"
    )
  }
  public static var mammal: Self {
    Self(
      categoryId: "Mammal",
      name: "Mammal"
    )
  }
  public static var reptile: Self {
    Self(
      categoryId: "Reptile",
      name: "Reptile"
    )
  }
}
