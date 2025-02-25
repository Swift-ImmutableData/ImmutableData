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

import Foundation
import SwiftData

//  https://developer.apple.com/forums/thread/761536
//  https://developer.apple.com/forums/thread/761637

@Model final package class QuakeModel {
  package var quakeId: String
  package var magnitude: Double
  package var time: Date
  package var updatedTime: Date
  package var name: String
  package var longitude: Double
  package var latitude: Double
  
  package init(
    quakeId: String,
    magnitude: Double,
    time: Date,
    updatedTime: Date,
    name: String,
    longitude: Double,
    latitude: Double
  ) {
    self.quakeId = quakeId
    self.magnitude = magnitude
    self.time = time
    self.updatedTime = updatedTime
    self.name = name
    self.longitude = longitude
    self.latitude = latitude
  }
}

extension QuakeModel {
  fileprivate func quake() -> Quake {
    Quake(
      quakeId: self.quakeId,
      magnitude: self.magnitude,
      time: self.time,
      updated: self.updatedTime,
      name: self.name,
      longitude: self.longitude,
      latitude: self.latitude
    )
  }
}

extension Quake {
  fileprivate func model() -> QuakeModel {
    QuakeModel(
      quakeId: self.quakeId,
      magnitude: self.magnitude,
      time: self.time,
      updatedTime: self.updated,
      name: self.name,
      longitude: self.longitude,
      latitude: self.latitude
    )
  }
}

extension QuakeModel {
  fileprivate func update(with quake: Quake) {
    self.quakeId = quake.quakeId
    self.magnitude = quake.magnitude
    self.time = quake.time
    self.updatedTime = quake.updated
    self.name = quake.name
    self.longitude = quake.longitude
    self.latitude = quake.latitude
  }
}

extension ModelContext {
  fileprivate func fetch<T>(_ type: T.Type) throws -> Array<T> where T : PersistentModel {
    try self.fetch(
      FetchDescriptor<T>()
    )
  }
}

extension ModelContext {
  fileprivate func fetch<T>(_ predicate: Predicate<T>) throws -> Array<T> where T : PersistentModel {
    try self.fetch(
      FetchDescriptor(predicate: predicate)
    )
  }
}

final package actor ModelActor: SwiftData.ModelActor {
  package nonisolated let modelContainer: ModelContainer
  package nonisolated let modelExecutor: any ModelExecutor
  
  fileprivate init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    let modelContext = ModelContext(modelContainer)
    modelContext.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
  }
}

extension ModelActor {
  fileprivate func fetchLocalQuakesQuery() throws -> Array<Quake> {
    let array = try self.modelContext.fetch(QuakeModel.self)
    return array.map { model in model.quake() }
  }
}

extension ModelActor {
  package struct Error: Swift.Error {
    package enum Code: Equatable {
      case quakeNotFound
    }
    
    package let code: Self.Code
  }
}

extension ModelActor {
  fileprivate func didFetchRemoteQuakesMutation(
    inserted: Array<Quake>,
    updated: Array<Quake>,
    deleted: Array<Quake>
  ) throws {
    for quake in inserted {
      let model = quake.model()
      self.modelContext.insert(model)
    }
    if updated.isEmpty == false {
      let set = Set(updated.map { $0.quakeId })
      let predicate = #Predicate<QuakeModel> { model in
        set.contains(model.quakeId)
      }
      let dictionary = Dictionary(uniqueKeysWithValues: updated.map { ($0.quakeId, $0) })
      for model in try self.modelContext.fetch(predicate) {
        guard
          let quake = dictionary[model.quakeId]
        else {
          throw Error(code: .quakeNotFound)
        }
        model.update(with: quake)
      }
    }
    if deleted.isEmpty == false {
      let set = Set(deleted.map { $0.quakeId })
      let predicate = #Predicate<QuakeModel> { model in
        set.contains(model.quakeId)
      }
      try self.modelContext.delete(
        model: QuakeModel.self,
        where: predicate
      )
    }
    try self.modelContext.save()
  }
}

extension ModelActor {
  fileprivate func deleteLocalQuakeMutation(quakeId: Quake.ID) throws {
    let predicate = #Predicate<QuakeModel> { model in
      model.quakeId == quakeId
    }
    try self.modelContext.delete(
      model: QuakeModel.self,
      where: predicate
    )
    try self.modelContext.save()
  }
}

extension ModelActor {
  fileprivate func deleteLocalQuakesMutation() throws {
    try self.modelContext.delete(model: QuakeModel.self)
    try self.modelContext.save()
  }
}

final public actor LocalStore {
  lazy package var modelActor = ModelActor(modelContainer: self.modelContainer)
  
  private let modelContainer: ModelContainer
  
  private init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }
}

extension LocalStore {
  private init(
    schema: Schema,
    configuration: ModelConfiguration
  ) throws {
    let container = try ModelContainer(
      for: schema,
      configurations: configuration
    )
    self.init(modelContainer: container)
  }
}

extension LocalStore {
  private static var models: Array<any PersistentModel.Type> {
    [QuakeModel.self]
  }
}

extension LocalStore {
  public init(url: URL) throws {
    let schema = Schema(Self.models)
    let configuration = ModelConfiguration(url: url)
    try self.init(
      schema: schema,
      configuration: configuration
    )
  }
}

extension LocalStore {
  public init(isStoredInMemoryOnly: Bool = false) throws {
    let schema = Schema(Self.models)
    let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
    try self.init(
      schema: schema,
      configuration: configuration
    )
  }
}

extension LocalStore: PersistentSessionLocalStore {
  public func fetchLocalQuakesQuery() async throws -> Array<Quake> {
    try await self.modelActor.fetchLocalQuakesQuery()
  }
  
  public func didFetchRemoteQuakesMutation(
    inserted: Array<Quake>,
    updated: Array<Quake>,
    deleted: Array<Quake>
  ) async throws {
    try await self.modelActor.didFetchRemoteQuakesMutation(
      inserted: inserted,
      updated: updated,
      deleted: deleted
    )
  }
  
  public func deleteLocalQuakeMutation(quakeId: Quake.ID) async throws {
    try await self.modelActor.deleteLocalQuakeMutation(quakeId: quakeId)
  }
  
  public func deleteLocalQuakesMutation() async throws {
    try await self.modelActor.deleteLocalQuakesMutation()
  }
}
