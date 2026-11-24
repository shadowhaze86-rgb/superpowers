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
struct LeonidaMapView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress
    @Environment(UserContentStore.self) private var userContent

    let focusID: String?

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var side: CGFloat = 1
    @State private var viewport: CGSize = .zero
    @State private var didFocus = false

    @State private var categories: Set<LocationCategory> = Set(LocationCategory.allCases)
    @State private var region: String?
    @State private var hideFound = false
    @State private var showUserPins = true

    @State private var selected: MapLocation?
    @State private var selectedPin: UserPin?
    @State private var editingPin: UserPin?
    @State private var hint: String?

    private let maxScale: CGFloat = 10

    private var visible: [MapLocation] {
        content.locations.filter {
            categories.contains($0.category)
                && (region == nil || $0.region == region)
                && !(hideFound && progress.isFound($0))
        }
    }

    /// Kartenpunkt (0…1), der gerade in der Bildschirmmitte liegt.
    private var centerPoint: CGPoint {
        CGPoint(x: min(max(0.5 - offset.width / (side * scale), 0), 1),
                y: min(max(0.5 - offset.height / (side * scale), 0), 1))
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
                        .onTapGesture { select(location) }
                }

                if showUserPins {
                    ForEach(userContent.pins) { pin in
                        UserPinMarker(pin: pin, selected: selectedPin?.id == pin.id)
                            .scaleEffect(1 / scale)
                            .position(x: pin.x * side, y: pin.y * side)
                            .onTapGesture { select(pin) }
                    }
                }
            }
            .frame(width: side, height: side)
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(zoomGesture.simultaneously(with: panGesture))
            .onTapGesture(count: 2) {
                withAnimation(.spring) { setScale(scale > 2 ? 1 : 3) }
            }
            .clipped()
            .overlay { Crosshair().allowsHitTesting(false) }
            .onAppear { updateLayout(geo.size) }
            .onChange(of: geo.size) { _, size in updateLayout(size) }
        }
        .background(Theme.night)
        .overlay(alignment: .top) { filterBar }
        .overlay(alignment: .bottom) { bottomPanel }
        .toolbar { toolbar }
        .sheet(item: $editingPin) { pin in
            PinEditor(pin: pin, isNew: !userContent.pins.contains { $0.id == pin.id })
        }
    }

    // MARK: - Unteres Panel

    @ViewBuilder private var bottomPanel: some View {
        if let selected {
            LocationCard(location: selected) { withAnimation { self.selected = nil } }
        } else if let pin = selectedPin {
            UserPinCard(pin: pin,
                        onEdit: { editingPin = pin },
                        onDelete: { userContent.delete(pin); withAnimation { selectedPin = nil } },
                        onClose: { withAnimation { selectedPin = nil } })
        } else if let hint {
            Text(hint)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 24)
                .transition(.opacity)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                Picker("Region", selection: $region) {
                    Text("Alle Regionen").tag(String?.none)
                    ForEach(content.regions, id: \.self) { Text($0).tag(String?.some($0)) }
                }
            } label: {
                Image(systemName: region == nil ? "globe.americas" : "globe.americas.fill")
            }

            Button(action: jumpToNearestCollectible) {
                Image(systemName: "star.circle")
            }
            .accessibilityLabel("Nächstes offenes Sammelobjekt")

            Button {
                let c = centerPoint
                editingPin = UserPin(name: "", note: "", x: c.x, y: c.y)
            } label: {
                Image(systemName: "mappin.and.ellipse.circle")
            }
            .accessibilityLabel("Eigenen Pin in der Kartenmitte setzen")

            Button {
                withAnimation(.spring) { setScale(1); offset = .zero; lastOffset = .zero }
            } label: { Image(systemName: "arrow.up.left.and.down.right.magnifyingglass") }
        }
    }

    // MARK: - Gesten & Kamera

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, 1), maxScale)
                offset = clamped(offset)
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = clamped(CGSize(width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height))
            }
            .onEnded { _ in lastOffset = offset }
    }

    /// Verhindert, dass die Karte komplett aus dem Bild geschoben wird.
    private func clamped(_ proposed: CGSize) -> CGSize {
        let maxX = max(0, (side * scale - viewport.width) / 2)
        let maxY = max(0, (side * scale - viewport.height) / 2)
        return CGSize(width: min(max(proposed.width, -maxX), maxX),
                      height: min(max(proposed.height, -maxY), maxY))
    }

    private func setScale(_ newScale: CGFloat) {
        scale = newScale
        lastScale = newScale
        offset = clamped(offset)
        lastOffset = offset
    }

    /// Zentriert die Karte auf einen Punkt (scaleEffect skaliert um den Mittelpunkt).
    private func center(on point: CGPoint, minScale: CGFloat = 3) {
        scale = max(scale, minScale)
        lastScale = scale
        offset = clamped(CGSize(width: (0.5 - point.x) * side * scale,
                                height: (0.5 - point.y) * side * scale))
        lastOffset = offset
    }

    private func updateLayout(_ size: CGSize) {
        viewport = size
        side = max(size.width, size.height, 1)
        if !didFocus, let location = content.location(id: focusID) {
            didFocus = true
            center(on: location.point)
            selected = location
        }
    }

    private func select(_ location: MapLocation) {
        withAnimation(.snappy) { selectedPin = nil; selected = location }
    }

    private func select(_ pin: UserPin) {
        withAnimation(.snappy) { selected = nil; selectedPin = pin }
    }

    private func jumpToNearestCollectible() {
        let origin = centerPoint
        let open = content.collectibles.filter {
            !progress.isFound($0) && (region == nil || $0.region == region)
        }
        guard let nearest = open.min(by: { distance($0.point, origin) < distance($1.point, origin) }) else {
            showHint(region == nil ? "Alle Sammelobjekte gefunden 🎉" : "In \(region!) ist alles gefunden 🎉")
            return
        }
        categories.insert(.collectible)
        withAnimation(.spring) {
            center(on: nearest.point)
            selectedPin = nil
            selected = nearest
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    private func showHint(_ text: String) {
        withAnimation { hint = text }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { hint = nil }
        }
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
                Toggle(isOn: $showUserPins) {
                    Label("Eigene Pins", systemImage: "mappin").font(.caption.weight(.bold))
                }
                .toggleStyle(.button)
                .tint(Color.white)
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

// MARK: - Marker

private struct Crosshair: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 18, weight: .light))
            .foregroundStyle(.white.opacity(0.5))
            .shadow(color: .black, radius: 2)
    }
}

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

struct UserPinMarker: View {
    let pin: UserPin
    let selected: Bool

    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: selected ? 34 : 26))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, Theme.purple)
            .shadow(color: Theme.purple, radius: selected ? 10 : 4)
            .accessibilityLabel("Eigener Pin: \(pin.name)")
    }
}

// MARK: - Info-Karten

private struct InfoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding()
            .frame(maxWidth: 520)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.stroke))
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private struct CloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(Theme.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

struct LocationCard: View {
    @Environment(ProgressStore.self) private var progress
    let location: MapLocation
    let onClose: () -> Void

    var body: some View {
        InfoCard {
            HStack {
                Label(location.category.label, systemImage: location.category.icon)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(location.category.color)
                if location.isPlaceholder { Pill(text: "Demo", color: Theme.sun) }
                if location.id.hasPrefix("import-") { Pill(text: "Import", color: Theme.teal) }
                Spacer()
                CloseButton(action: onClose)
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
                    Label(progress.isFound(location) ? "Erledigt ✓" : "Als erledigt markieren",
                          systemImage: progress.isFound(location) ? "checkmark.circle.fill" : "circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(progress.isFound(location) ? Theme.teal : Theme.pink)
                .sensoryFeedback(.success, trigger: progress.isFound(location))
            }
        }
    }
}

struct UserPinCard: View {
    let pin: UserPin
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    var body: some View {
        InfoCard {
            HStack {
                Label("Eigener Pin", systemImage: "mappin").font(.caption.weight(.heavy)).foregroundStyle(Theme.purple)
                Spacer()
                CloseButton(action: onClose)
            }
            Text(pin.name.isEmpty ? "Ohne Namen" : pin.name).font(Theme.title(22)).italic()
            if !pin.note.isEmpty { Text(pin.note).font(.footnote) }
            HStack {
                Button(action: onEdit) { Label("Bearbeiten", systemImage: "pencil").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered).tint(Theme.teal)
                Button(role: .destructive, action: onDelete) { Label("Löschen", systemImage: "trash").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct PinEditor: View {
    @Environment(UserContentStore.self) private var userContent
    @Environment(\.dismiss) private var dismiss
    @State var pin: UserPin
    let isNew: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $pin.name)
                TextField("Notiz", text: $pin.note, axis: .vertical).lineLimit(3...8)
            }
            .navigationTitle(isNew ? "Neuer Pin" : "Pin bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        if isNew { userContent.add(pin) } else { userContent.update(pin) }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
