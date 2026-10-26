import SwiftUI

struct BrandMark: View {
    var size: CGFloat = 36

    private func grainFill(for index: Int) -> LinearGradient {
        let angle = CGFloat(index) * .pi * 2 / 5
        return LinearGradient(
            colors: Palette.brandGrains[index],
            startPoint: UnitPoint(x: 0.5 + sin(angle) * 0.355, y: 0.5 - cos(angle) * 0.355),
            endPoint: UnitPoint(x: 0.5 + sin(angle) * 0.035, y: 0.5 - cos(angle) * 0.035)
        )
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "B36E51"), Color(hex: "80526A")], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "F5C79F").opacity(0.42), Color(hex: "F5C79F").opacity(0)]),
                center: UnitPoint(x: 0.06, y: 0.04), startRadius: 0, endRadius: size * 0.96
            )
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "B9C99D").opacity(0.26), Color(hex: "B9C99D").opacity(0)]),
                center: UnitPoint(x: 1, y: 0.08), startRadius: 0, endRadius: size * 0.82
            )
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "E8CA7B").opacity(0.32), Color(hex: "E8CA7B").opacity(0)]),
                center: UnitPoint(x: 0.08, y: 1), startRadius: 0, endRadius: size * 0.90
            )
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "B9A3D1").opacity(0.46), Color(hex: "B9A3D1").opacity(0)]),
                center: .bottomTrailing, startRadius: 0, endRadius: size * 1.05
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: size * 0.29, style: .continuous))
    }

    var body: some View {
        ZStack {
            background
            Circle()
                .stroke(Color(hex: "F8EBD5").opacity(0.17), lineWidth: size / 512)
                .frame(width: size * 0.744140625, height: size * 0.744140625)
            ForEach(Palette.brandGrains.indices, id: \.self) { index in
                GrainBloom(petalIndex: index).fill(grainFill(for: index)).padding(size * 0.09)
            }
            Circle().fill(Color(hex: "DFB77E")).frame(width: size * 0.0656, height: size * 0.0656)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(.title3, design: .serif).weight(.medium)).foregroundColor(Palette.text)
            if let subtitle = subtitle { Text(subtitle).font(.subheadline).lineSpacing(3).foregroundColor(Palette.secondary).fixedSize(horizontal: false, vertical: true) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IconBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let symbol: String
    var color: Color = Palette.accent
    var size: CGFloat = 42
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.41, weight: .medium))
            .foregroundColor(color.readableInk(in: colorScheme))
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [color.opacity(0.22), color.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous).stroke(color.opacity(0.16), lineWidth: 1))
            .accessibilityHidden(true)
    }
}

struct TagChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let symbol: String
    var color: Color = Palette.accent
    var selected = false
    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(.caption, design: .rounded).weight(.medium))
            .padding(.horizontal, 12).padding(.vertical, 9)
            .foregroundColor(selected ? color.readableForeground(in: colorScheme) : color.readableInk(in: colorScheme))
            .background {
                ZStack {
                    Palette.surface
                    LinearGradient(colors: [color.opacity(selected ? 1 : 0.16), color.opacity(selected ? 1 : 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(color.opacity(selected ? 0.50 : 0.23), lineWidth: 1))
    }
}

struct StatTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let value: String
    let title: String
    let symbol: String
    var color: Color = Palette.accent
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IconBadge(symbol: symbol, color: color, size: 33)
            Text(value).font(.system(size: 29, weight: .semibold, design: .rounded)).foregroundColor(color.readableInk(in: colorScheme)).minimumScaleFactor(0.65)
            Text(title).font(.caption).foregroundColor(Palette.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .surface(padding: 15, tint: color)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            IconBadge(symbol: symbol, size: 66)
            Text(title).font(.system(.title3, design: .rounded).weight(.semibold)).foregroundColor(Palette.text)
            Text(message).font(.subheadline).foregroundColor(Palette.secondary).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22).padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

@MainActor
struct EntryCard: View {
    @EnvironmentObject private var store: JournalStore
    let entry: JournalEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                IconBadge(symbol: entry.kind.symbol, color: entry.kind.tone.ink, size: 36)
                Text(entry.kind.title.uppercased()).tracking(1.2).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(Palette.secondary)
                Spacer()
                if entry.isFavorite { Image(systemName: "bookmark.fill").font(.caption).foregroundColor(Palette.gold).accessibilityLabel("Favorite") }
                Text(EnglishDate.string(entry.date, template: "MMM d")).font(.caption).foregroundColor(Palette.secondary)
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundColor(Palette.secondary.opacity(0.6))
            }
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(entry.title).font(.system(.headline, design: .serif)).foregroundColor(Palette.text).lineLimit(2)
                    if !entry.preview.isEmpty {
                        Text(entry.preview).font(.subheadline).foregroundColor(Palette.secondary).lineLimit(2).lineSpacing(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let first = entry.photoIDs.first, let image = store.image(for: first, thumbnail: true) {
                    Image(uiImage: image).resizable().scaledToFill().frame(width: 66, height: 72).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Attached photo")
                }
            }
            if !entry.fieldbookIDs.isEmpty || !store.linkedEntries(for: entry).isEmpty {
                let connected = store.linkedEntries(for: entry).count
                HStack(spacing: 12) {
                    if !entry.fieldbookIDs.isEmpty { Label("\(entry.fieldbookIDs.count) \(entry.fieldbookIDs.count == 1 ? "fieldbook" : "fieldbooks")", systemImage: "books.vertical") }
                    if connected > 0 { Label("\(connected) connected", systemImage: "link") }
                }.font(.caption2).foregroundColor(Palette.secondary)
            }
            if entry.kind == .sensory && !entry.observations.isEmpty {
                HStack(spacing: 7) {
                    ForEach(entry.observations) { item in
                        Image(systemName: item.sense.symbol).font(.system(size: 12)).foregroundColor(item.sense.tint)
                            .frame(width: 28, height: 27).background(item.sense.tint.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityLabel(item.sense.title)
                    }
                    Spacer()
                    if !entry.location.isEmpty { Label(entry.location, systemImage: "mappin").font(.caption2).foregroundColor(Palette.secondary).lineLimit(1) }
                }
            } else if entry.kind == .emotion {
                let tags = store.tags(for: entry)
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(tags) { tag in TagChip(title: tag.name, symbol: tag.symbol, color: Color(hex: tag.colorHex)) }
                        }
                    }
                }
            }
        }
        .surface(tint: entry.kind.tone.ink)
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct EditorTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 110
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder).font(.body).foregroundColor(Palette.secondary.opacity(0.8)).padding(.horizontal, 5).padding(.top, 8).allowsHitTesting(false)
            }
            TextEditor(text: $text).frame(minHeight: minHeight).opacity(text.isEmpty ? 0.65 : 1)
                .accessibilityLabel(placeholder)
        }
    }
}

struct LevelSelector: View {
    let title: String
    let low: String
    let high: String
    @Binding var value: Int
    var color: Color = Palette.accent
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(value) / 5").font(.system(.caption, design: .rounded).weight(.semibold)).foregroundColor(color)
            }
            HStack(spacing: 9) {
                ForEach(1...5, id: \.self) { level in
                    Button { value = level } label: {
                        VStack(spacing: 7) {
                            Text("\(level)").font(.system(.caption, design: .rounded).weight(.semibold))
                            Capsule().fill(level <= value ? color : Palette.line).frame(height: 5)
                        }
                        .foregroundColor(value == level ? color : Palette.secondary)
                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                        .background(value == level ? color.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(value == level ? color.opacity(0.28) : .clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title), \(level) of 5")
                    .accessibilityAddTraits(value == level ? .isSelected : [])
                }
            }
            HStack {
                Text(low)
                Spacer()
                Text(high)
            }.font(.caption2).foregroundColor(Palette.secondary)
        }
        .foregroundColor(Palette.text)
    }
}

struct SettingsRow: View {
    let symbol: String
    let title: String
    var subtitle: String? = nil
    var color: Color = Palette.accent
    var chevron = true
    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: symbol, color: color, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.medium)).foregroundColor(Palette.text)
                if let subtitle = subtitle { Text(subtitle).font(.caption).foregroundColor(Palette.secondary) }
            }
            Spacer(minLength: 8)
            if chevron { Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(Palette.secondary) }
        }
        .padding(.vertical, 5).contentShape(Rectangle())
    }
}
