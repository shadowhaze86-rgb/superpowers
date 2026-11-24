import SwiftUI

struct MapScreen: View {
    var body: some View {
        NavigationStack {
            LeonidaMapView(focusID: nil)
                .navigationTitle("Karte")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Zoom- und verschiebbare Karte mit Pins in normalisierten Koordinaten (0…1).
/// Der Kartenhintergrund ist austauschbar (siehe `MapBackground`).
struct LeonidaMapView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress

    let focusID: String?

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var categories: Set<LocationCategory> = Set(LocationCategory.allCases)
    @State private var hideFound = false
    @State private var selected: MapLocation?

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 8

    private var visible: [MapLocation] {
        content.locations.filter {
            categories.contains($0.category) && !(hideFound && progress.isFound($0))
        }
    }

    var body: some View {
        GeometryReader { geo in
            let side = max(geo.size.width, geo.size.height)
            ZStack {
                MapBackground()
                    .frame(width: side, height: side)

                ForEach(visible) { location in
                    MapPin(location: location,
                           found: progress.isFound(location),
                           selected: selected?.id == location.id)
                        .scaleEffect(1 / scale)
                        .position(x: location.x * side, y: location.y * side)
                        .onTapGesture {
                            withAnimation(.snappy) { selected = location }
                        }
                }
            }
            .frame(width: side, height: side)
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(zoom(side: side, viewport: geo.size).simultaneously(with: pan(side: side, viewport: geo.size)))
            .onTapGesture(count: 2) {
                withAnimation(.spring) { zoomTo(scale > 2 ? 1 : 3, side: side, viewport: geo.size) }
            }
            .clipped()
            .onAppear { focus(side: side, viewport: geo.size) }
        }
        .background(Theme.night)
        .overlay(alignment: .top) { filterBar }
        .overlay(alignment: .bottom) {
            if let selected { LocationCard(location: selected) { self.selected = nil } }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.spring) {
                        scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
                    }
                } label: { Image(systemName: "arrow.up.left.and.down.right.magnifyingglass") }
            }
        }
    }

    // MARK: - Gesten

    private func zoom(side: CGFloat, viewport: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, minScale), maxScale)
                offset = clamped(offset, side: side, viewport: viewport)
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    private func pan(side: CGFloat, viewport: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(width: lastOffset.width + value.translation.width,
                                      height: lastOffset.height + value.translation.height)
                offset = clamped(proposed, side: side, viewport: viewport)
            }
            .onEnded { _ in lastOffset = offset }
    }

    /// Verhindert, dass die Karte komplett aus dem Bild geschoben wird.
    private func clamped(_ proposed: CGSize, side: CGFloat, viewport: CGSize) -> CGSize {
        let maxX = max(0, (side * scale - viewport.width) / 2)
        let maxY = max(0, (side * scale - viewport.height) / 2)
        return CGSize(width: min(max(proposed.width, -maxX), maxX),
                      height: min(max(proposed.height, -maxY), maxY))
    }

    private func zoomTo(_ newScale: CGFloat, side: CGFloat, viewport: CGSize) {
        scale = newScale
        lastScale = newScale
        offset = clamped(offset, side: side, viewport: viewport)
        lastOffset = offset
    }

    private func focus(side: CGFloat, viewport: CGSize) {
        guard let location = content.location(id: focusID) else { return }
        scale = 3
        lastScale = 3
        // scaleEffect skaliert um den Mittelpunkt → Punkt in die Bildschirmmitte verschieben
        offset = clamped(CGSize(width: (0.5 - location.x) * side * scale,
                                height: (0.5 - location.y) * side * scale),
                         side: side, viewport: viewport)
        lastOffset = offset
        selected = location
    }

    // MARK: - Filter

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LocationCategory.allCases) { category in
                    let active = categories.contains(category)
                    Button {
                        if active { categories.remove(category) } else { categories.insert(category) }
                    } label: {
                        Label(category.label, systemImage: category.icon)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(active ? category.color.opacity(0.85) : Color.black.opacity(0.5), in: Capsule())
                            .foregroundStyle(active ? Color.black : Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                Toggle(isOn: $hideFound) {
                    Text("Gefundene ausblenden").font(.caption.weight(.bold))
                }
                .toggleStyle(.button)
                .tint(Theme.teal)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Pin & Info-Karte

struct MapPin: View {
    let location: MapLocation
    let found: Bool
    let selected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(location.category.color.gradient)
                .frame(width: selected ? 38 : 28, height: selected ? 38 : 28)
                .shadow(color: location.category.color.opacity(0.9), radius: selected ? 12 : 5)
            Image(systemName: found ? "checkmark" : location.category.icon)
                .font(.system(size: selected ? 16 : 12, weight: .bold))
                .foregroundStyle(.black)
        }
        .opacity(found ? 0.55 : 1)
        .overlay(alignment: .bottom) {
            if location.category == .landmark {
                Text(location.name.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 3)
                    .fixedSize()
                    .offset(y: 18)
            }
        }
        .accessibilityLabel("\(location.category.label): \(location.name)")
    }
}

struct LocationCard: View {
    @Environment(ProgressStore.self) private var progress
    let location: MapLocation
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(location.category.label, systemImage: location.category.icon)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(location.category.color)
                if location.isPlaceholder { Pill(text: "Demo", color: Theme.sun) }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            Text(location.name).font(Theme.title(22)).italic()
            Text(location.region).font(.subheadline).foregroundStyle(Theme.textSecondary)
            if let note = location.note {
                Text(note).font(.footnote).foregroundStyle(.white.opacity(0.85))
            }
            if location.category != .landmark {
                Button {
                    withAnimation(.snappy) { progress.toggleFound(location) }
                } label: {
                    Label(progress.isFound(location) ? "Gefunden ✓" : "Als gefunden markieren",
                          systemImage: progress.isFound(location) ? "checkmark.circle.fill" : "circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(progress.isFound(location) ? Theme.teal : Theme.pink)
            }
        }
        .padding()
        .frame(maxWidth: 520)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.stroke))
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
