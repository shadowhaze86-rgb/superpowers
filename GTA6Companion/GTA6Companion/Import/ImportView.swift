import SwiftUI
import UniformTypeIdentifiers

/// Import von Kartenpunkten aus einer Datei, inklusive Kalibrierung und Vorschau.
struct ImportView: View {
    @Environment(ContentStore.self) private var content
    @Environment(\.dismiss) private var dismiss

    @State private var showPicker = false
    @State private var fileName = ""
    @State private var points: [LocationImporter.RawPoint] = []
    @State private var calibration = LocationImporter.Calibration(minA: 0, maxA: 1, minB: 0, maxB: 1, flipB: false, swap: false)
    @State private var error: String?
    @State private var imported = 0

    private var preview: [MapLocation] {
        LocationImporter.makeLocations(points, calibration: calibration, source: "preview")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { showPicker = true } label: {
                        Label(points.isEmpty ? "Datei auswählen" : "Andere Datei", systemImage: "doc.badge.plus")
                    }
                    if !fileName.isEmpty {
                        LabeledContent(fileName, value: "\(points.count) Punkte")
                    }
                    if let error {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                } footer: {
                    Text("JSON (App-Format), GeoJSON (FeatureCollection mit Punkten) oder CSV mit den Spalten name, category, region, x, y, note.")
                }

                if !points.isEmpty {
                    Section {
                        calibrationRow("X / Lng", min: $calibration.minA, max: $calibration.maxA)
                        calibrationRow("Y / Lat", min: $calibration.minB, max: $calibration.maxB)
                        Toggle("Y-Achse umkehren", isOn: $calibration.flipB)
                        Toggle("Achsen tauschen", isOn: $calibration.swap)
                    } header: {
                        Text("Kalibrierung")
                    } footer: {
                        Text("Wertebereich der Quelle, der auf die gesamte Kartenbreite bzw. -höhe abgebildet wird. Bei Leaflet-Karten entspricht das den Kartengrenzen (bounds). Die Vorschau zeigt das Ergebnis.")
                    }

                    Section("Vorschau") {
                        CalibrationPreview(locations: preview)
                            .frame(height: 280)
                            .listRowInsets(EdgeInsets())
                    }

                    Section {
                        Button {
                            do {
                                let source = fileName.replacingOccurrences(of: " ", with: "-")
                                let items = LocationImporter.makeLocations(points, calibration: calibration, source: source)
                                try content.addImported(items)
                                imported = items.count
                            } catch {
                                self.error = error.localizedDescription
                            }
                        } label: {
                            Label("\(points.count) Punkte importieren", systemImage: "square.and.arrow.down.fill")
                        }
                        .tint(Theme.pink)
                    }
                }
            }
            .navigationTitle("Punkte importieren")
            .navigationBarTitleDisplayMode(.inline)
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Schließen") { dismiss() } }
            }
            .fileImporter(isPresented: $showPicker,
                          allowedContentTypes: [.json, .commaSeparatedText, UTType(filenameExtension: "geojson") ?? .json]) { result in
                load(result)
            }
            .alert("Import abgeschlossen", isPresented: Binding(get: { imported > 0 }, set: { if !$0 { imported = 0; dismiss() } })) {
                Button("OK") {}
            } message: {
                Text("\(imported) Punkte wurden zur Karte hinzugefügt.")
            }
        }
    }

    private func calibrationRow(_ title: String, min: Binding<Double>, max: Binding<Double>) -> some View {
        HStack {
            Text(title).frame(width: 70, alignment: .leading)
            TextField("min", value: min, format: .number).keyboardType(.numbersAndPunctuation)
            TextField("max", value: max, format: .number).keyboardType(.numbersAndPunctuation)
        }
        .textFieldStyle(.roundedBorder)
    }

    private func load(_ result: Result<URL, Error>) {
        error = nil
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            points = try LocationImporter.parse(data, fileExtension: url.pathExtension)
            calibration = .fitting(points)
            fileName = url.deletingPathExtension().lastPathComponent
        } catch {
            points = []
            self.error = error.localizedDescription
        }
    }
}

private struct CalibrationPreview: View {
    let locations: [MapLocation]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                MapBackground().frame(width: side, height: side).clipped()
                Canvas { context, size in
                    for location in locations {
                        let r: CGFloat = 3
                        let rect = CGRect(x: location.x * size.width - r, y: location.y * size.height - r,
                                          width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(location.category.color))
                    }
                }
                .frame(width: side, height: side)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
