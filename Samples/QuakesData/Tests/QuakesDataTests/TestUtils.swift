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

import Algorithms
import Collections

extension Dictionary {
  public init(_ values: Value...) where Key == Value.ID, Value : Identifiable {
    self.init(values)
  }
}

extension Dictionary {
  public init<S>(_ values: S) where Key == Value.ID, Value : Identifiable, S : Sequence, S.Element == Value {
    self.init(
      uniqueKeysWithValues: values.map { element in
        (element.id, element)
      }
    )
  }
}

func product<Base1, Base2>(
  _ s1: Base1,
  _ s2: Base2
) -> Array<(Base1.Element, Base2.Element)> where Base1 : Sequence, Base2 : Collection {
  var result = Array<(Base1.Element, Base2.Element)>()
  
  let p1 = Algorithms.product(s1, s2)
  
  for (b1, b2) in p1 {
    result.append((b1, b2))
  }
  
  return result
}

func product<Base1, Base2, Base3>(
  _ s1: Base1,
  _ s2: Base2,
  _ s3: Base3
) -> Array<(Base1.Element, Base2.Element, Base3.Element)> where Base1 : Sequence, Base2 : Collection, Base3 : Collection {
  var result = Array<(Base1.Element, Base2.Element, Base3.Element)>()
  
  let p1 = Algorithms.product(s1, s2)
  let p2 = Algorithms.product(p1, s3)
  
  for ((b1, b2), b3) in p2 {
    result.append((b1, b2, b3))
  }
  
  return result
}

func product<Base1, Base2, Base3, Base4>(
  _ s1: Base1,
  _ s2: Base2,
  _ s3: Base3,
  _ s4: Base4
) -> Array<(Base1.Element, Base2.Element, Base3.Element, Base4.Element)> where Base1 : Sequence, Base2 : Collection, Base3 : Collection, Base4 : Collection {
  var result = Array<(Base1.Element, Base2.Element, Base3.Element, Base4.Element)>()
  
  let p1 = Algorithms.product(s1, s2)
  let p2 = Algorithms.product(p1, s3)
  let p3 = Algorithms.product(p2, s4)
  
  for (((b1, b2), b3), b4) in p3 {
    result.append((b1, b2, b3, b4))
  }
  
  return result
}

extension TreeDictionary {
  init(_ values: Value...) where Key == Value.ID, Value : Identifiable {
    self.init(values)
  }
}

extension TreeDictionary {
  init<S>(_ values: S) where Key == Value.ID, Value : Identifiable, S : Sequence, S.Element == Value {
    self.init(
      uniqueKeysWithValues: values.map { element in
        (element.id, element)
      }
    )
  }
}
