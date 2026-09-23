import MapKit
import RallyUpCore
import SwiftUI

struct CourtsView: View {
    @EnvironmentObject private var store: RallyStore
    @State private var searchText = ""
    @State private var selectedCourtID: UUID?
    @ScaledMetric(relativeTo: .body) private var selectedPinFontSize = 26.0
    @ScaledMetric(relativeTo: .body) private var pinFontSize = 22.0
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 14.558, longitude: 121.047),
            span: MKCoordinateSpan(latitudeDelta: 0.075, longitudeDelta: 0.075)
        )
    )

    private var visibleCourts: [TennisCourt] {
        store.courts.filter { court in
            searchText.isEmpty || court.name.localizedCaseInsensitiveContains(searchText) || court.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Map(position: $cameraPosition) {
                    ForEach(visibleCourts) { court in
                        Annotation(court.name, coordinate: coordinate(for: court), anchor: .bottom) {
                            Button { select(court) } label: {
                                Image(systemName: selectedCourtID == court.id ? "mappin.and.ellipse" : "mappin")
                                    .font(.system(size: selectedCourtID == court.id ? selectedPinFontSize : pinFontSize, weight: .semibold))
                                    .foregroundStyle(selectedCourtID == court.id ? RallyTheme.darkGreen : .primary)
                                    .padding(8)
                                    .background(selectedCourtID == court.id ? RallyTheme.tennis : RallyTheme.card, in: Circle())
                                    .shadow(color: .black.opacity(0.13), radius: 7, y: 3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(court.name)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))

                SectionHeading(title: "Nearby courts", actionTitle: "\(visibleCourts.count) found") { }

                if visibleCourts.isEmpty {
                    EmptyStateView(title: "No courts found", message: "Try another name or part of the address.", symbol: "sportscourt")
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(visibleCourts) { court in
                            CourtRow(court: court, selected: selectedCourtID == court.id) {
                                select(court)
                            }
                            if court.id != visibleCourts.last?.id {
                                Divider().padding(.leading, 74)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
                }
            }
            .padding(.horizontal, RallyTheme.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(RallyTheme.canvas.ignoresSafeArea())
        .navigationTitle("Courts")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search courts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 14.558, longitude: 121.047),
                            span: MKCoordinateSpan(latitudeDelta: 0.075, longitudeDelta: 0.075)
                        ))
                    }
                } label: {
                    Image(systemName: "scope")
                }
                .accessibilityLabel("Show courts in Metro Manila")
            }
        }
    }

    private func select(_ court: TennisCourt) {
        selectedCourtID = court.id
        withAnimation(.snappy) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate(for: court),
                span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
            ))
        }
    }

    private func coordinate(for court: TennisCourt) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: court.latitude, longitude: court.longitude)
    }
}

private struct CourtRow: View {
    let court: TennisCourt
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RallyTheme.darkGreen)
                    .frame(width: 54, height: 54)
                    .overlay {
                        Image(systemName: "sportscourt")
                            .font(.headline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(court.name).font(.subheadline).lineLimit(1)
                    Text(court.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(court.surface) · \(court.setting)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selected ? RallyTheme.tennis.opacity(0.15) : Color.clear)
        .accessibilityHint("Centers this court on the map")
    }
}
