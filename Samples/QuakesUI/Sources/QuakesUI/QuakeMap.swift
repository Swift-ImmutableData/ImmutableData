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

import Collections
import CoreLocation
import MapKit
import QuakesData
import SwiftUI

//  https://developer.apple.com/forums/thread/771084

@MainActor fileprivate struct QuakeCircle {
  private let quake: Quake
  private let selected: Bool
  
  init(
    quake: Quake,
    selected: Bool
  ) {
    self.quake = quake
    self.selected = selected
  }
}

extension QuakeCircle {
  var markerSize: CGSize {
    let value = (self.quake.magnitude + 3) * 6
    return CGSize(width: value, height: value)
  }
}

extension QuakeCircle: View {
  var body: some View {
    Circle()
      .stroke(
        self.selected ? .black : .gray,
        style: StrokeStyle(
          lineWidth: self.selected ? 2 : 1
        )
      )
      .fill(
        self.quake.color.opacity(
          self.selected ? 1 : 0.5
        )
      )
      .frame(
        width: self.markerSize.width,
        height: self.markerSize.width
      )
  }
}

#Preview {
  ForEach(Quake.previewQuakes) { quake in
    HStack {
      QuakeCircle(
        quake: quake,
        selected: false
      ).padding()
      QuakeCircle(
        quake: quake,
        selected: true
      ).padding()
    }
  }
}

@MainActor fileprivate struct QuakeMarker {
  private let quake: Quake
  private let selected: Bool
  
  init(
    quake: Quake,
    selected: Bool
  ) {
    self.quake = quake
    self.selected = selected
  }
}

extension QuakeMarker: MapContent {
  var body: some MapContent {
    Annotation(coordinate: self.quake.coordinate) {
      QuakeCircle(quake: self.quake, selected: selected)
    } label: {
      Text(self.quake.name)
    }
    .annotationTitles(.hidden)
    .tag(self.quake)
  }
}

@MainActor struct QuakeMap {
  private let listSelection: Quake.ID?
  @Binding private var mapSelection: Quake.ID?
  private let searchText: String
  private let searchDate: Date
  
  init(
    listSelection: Quake.ID?,
    mapSelection: Binding<Quake.ID?>,
    searchText: String,
    searchDate: Date
  ) {
    self.listSelection = listSelection
    self._mapSelection = mapSelection
    self.searchText = searchText
    self.searchDate = searchDate
  }
}

extension QuakeMap: View {
  var body: some View {
    let _ = Self.debugPrint()
    Container(
      listSelection: self.listSelection,
      mapSelection: self.$mapSelection,
      searchText: self.searchText,
      searchDate: self.searchDate
    )
  }
}

extension QuakeMap {
  @MainActor fileprivate struct Container {
    @SelectQuakes private var quakes: TreeDictionary<Quake.ID, Quake>
    @SelectQuake var listQuake: Quake?
    @SelectQuake var mapQuake: Quake?
    
    private let listSelection: Quake.ID?
    @Binding private var mapSelection: Quake.ID?
    
    init(
      listSelection: Quake.ID?,
      mapSelection: Binding<Quake.ID?>,
      searchText: String,
      searchDate: Date
    ) {
      self._quakes = SelectQuakes(
        searchText: searchText,
        searchDate: searchDate
      )
      self._listQuake = SelectQuake(quakeId: listSelection)
      self._mapQuake = SelectQuake(quakeId: mapSelection.wrappedValue)
      self.listSelection = listSelection
      self._mapSelection = mapSelection
    }
  }
}

extension QuakeMap.Container: View {
  var body: some View {
    let _ = Self.debugPrint()
    QuakeMap.Presenter(
      quakes: self.quakes,
      listQuake: self.listQuake,
      mapQuake: self.mapQuake,
      listSelection: self.listSelection,
      mapSelection: self.$mapSelection
    )
  }
}

extension QuakeMap {
  @MainActor fileprivate struct Presenter {
    private let quakes: TreeDictionary<Quake.ID, Quake>
    private let listQuake: Quake?
    private let mapQuake: Quake?
    private let listSelection: Quake.ID?
    @Binding private var mapSelection: Quake.ID?
    
    init(
      quakes: TreeDictionary<Quake.ID, Quake>,
      listQuake: Quake?,
      mapQuake: Quake?,
      listSelection: Quake.ID?,
      mapSelection: Binding<Quake.ID?>
    ) {
      self.quakes = quakes
      self.listQuake = listQuake
      self.mapQuake = mapQuake
      self.listSelection = listSelection
      self._mapSelection = mapSelection
    }
  }
}

extension CLLocationCoordinate2D {
  fileprivate func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
    let a = MKMapPoint(self);
    let b = MKMapPoint(coordinate);
    return a.distance(to: b)
  }
}

extension QuakeMap.Presenter {
  @KeyframesBuilder<MapCamera> private func keyframes(initialCamera: MapCamera) -> some Keyframes<MapCamera> {
    let start = initialCamera.centerCoordinate
    let end = self.listQuake?.coordinate ?? start
    let travelDistance = start.distance(to: end)
    
    let duration = max(min(travelDistance / 30, 5), 1)
    let finalAltitude = travelDistance > 20 ? 3_000_000 : min(initialCamera.distance, 3_000_000)
    let middleAltitude = finalAltitude * max(min(travelDistance / 5, 1.5), 1)
    
    KeyframeTrack(\MapCamera.centerCoordinate) {
      CubicKeyframe(end, duration: duration)
    }
    KeyframeTrack(\MapCamera.distance) {
      CubicKeyframe(middleAltitude, duration: duration / 2)
      CubicKeyframe(finalAltitude, duration: duration / 2)
    }
  }
}

extension QuakeMap.Presenter {
  private var map: some View {
    Map(selection: self.$mapSelection) {
      ForEach(Array(self.quakes.values)) { quake in
        QuakeMarker(quake: quake, selected: quake.id == self.mapSelection)
      }
    }
    .mapCameraKeyframeAnimator(
      trigger: self.listQuake,
      keyframes: self.keyframes
    )
    .mapStyle(
      .standard(
        elevation: .flat,
        emphasis: .muted,
        pointsOfInterest: .excludingAll
      )
    )
  }
}

extension QuakeMap.Presenter: View {
  var body: some View {
    let _ = Self.debugPrint()
    self.map
      .onChange(
        of: self.listSelection,
        initial: true
      ) {
        if self.mapSelection != self.listSelection {
          self.mapSelection = self.listSelection
        }
      }
      .navigationTitle(self.mapQuake?.name ?? "Earthquakes")
      .navigationSubtitle(self.mapQuake?.fullDate ?? "")
  }
}

#Preview {
  @Previewable @State var mapSelection: Quake.ID?
  PreviewStore {
    QuakeMap(
      listSelection: nil,
      mapSelection: $mapSelection,
      searchText: "",
      searchDate: .now
    )
  }
}

#Preview {
  @Previewable @State var mapSelection: Quake.ID?
  QuakeMap.Presenter(
    quakes: TreeDictionary(uniqueKeysWithValues: Quake.previewQuakes.map { ($0.quakeId, $0) }),
    listQuake: nil,
    mapQuake: nil,
    listSelection: nil,
    mapSelection: $mapSelection
  )
}
