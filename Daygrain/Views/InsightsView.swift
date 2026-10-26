import SwiftUI

private enum InsightRange: String, CaseIterable {
    case week = "7 days", month = "30 days", quarter = "90 days", all = "All time"
    var days: Int? {
        switch self { case .week: return 7; case .month: return 30; case .quarter: return 90; case .all: return nil }
    }
}

private struct ActivityBucket: Identifiable {
    let date: Date
    let end: Date
    let entries: [JournalEntry]
    var id: Date { date }
    var sensory: Int { entries.filter { $0.kind == .sensory }.count }
    var emotion: Int { entries.filter { $0.kind == .emotion }.count }
    var emotionEntries: [JournalEntry] { entries.filter { $0.kind == .emotion } }
    var intensity: Double? { emotionEntries.isEmpty ? nil : Double(emotionEntries.map(\.intensity).reduce(0, +)) / Double(emotionEntries.count) }
    var energy: Double? { emotionEntries.isEmpty ? nil : Double(emotionEntries.map(\.energy).reduce(0, +)) / Double(emotionEntries.count) }
}

private struct NoteCollection: Identifiable {
    let id = UUID()
    let title: String
    let entryIDs: [UUID]
    var onlyLoose = false
}

@MainActor
struct InsightsView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var range: InsightRange = .month
    @State private var selectedBucket: Date?
    @State private var collection: NoteCollection?
    @State private var fieldbookID: UUID?
    @State private var composer: ComposerRequest?

    private var scopedEntries: [JournalEntry] {
        guard let id = fieldbookID else { return store.entries }
        return store.entries.filter { $0.fieldbookIDs.contains(id) }
    }
    private var canCapture: Bool { fieldbookID == nil || !(store.fieldbooks.first { $0.id == fieldbookID }?.isArchived ?? false) }

    private var start: Date {
        if let days = range.days { return Calendar.current.date(byAdding: .day, value: -(days - 1), to: Calendar.current.startOfDay(for: Date()))! }
        return Calendar.current.startOfDay(for: scopedEntries.map(\.date).min() ?? Date())
    }
    private var entries: [JournalEntry] { scopedEntries.filter { $0.date >= start && $0.date <= Date() } }
    private var previousEntries: [JournalEntry] {
        let currentStart = start
        let currentEnd = Date()
        guard let days = range.days,
              let previousStart = Calendar.current.date(byAdding: .day, value: -days, to: currentStart) else { return [] }
        let previousEnd = previousStart.addingTimeInterval(max(0, currentEnd.timeIntervalSince(currentStart)))
        return scopedEntries.filter { $0.date >= previousStart && $0.date < previousEnd }
    }
    private var emotions: [JournalEntry] { entries.filter { $0.kind == .emotion } }
    private var sensory: [JournalEntry] { entries.filter { $0.kind == .sensory } }
    private var activeDays: Int { Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count }
    private var buckets: [ActivityBucket] {
        let calendar = Calendar.current
        let dayCount = max(1, (calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: Date())).day ?? 0) + 1)
        let step = max(1, Int(ceil(Double(dayCount) / 10)))
        return stride(from: 0, to: dayCount, by: step).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let end = calendar.date(byAdding: .day, value: min(step, dayCount - offset), to: day) else { return nil }
            return ActivityBucket(date: day, end: end, entries: entries.filter { $0.date >= day && $0.date < end })
        }
    }
    private var tagCounts: [(tag: EmotionTag, count: Int)] {
        store.emotionTags.map { tag in (tag, emotions.filter { $0.emotionTagIDs.contains(tag.id) }.count) }
            .filter { $0.1 > 0 }.sorted { $0.1 == $1.1 ? $0.0.name < $1.0.name : $0.1 > $1.1 }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 23) {
                    dashboardHeader
                    timeSelector
                    VStack(spacing: 15) {
                        overview
                        periodComparison
                    }
                    activityChart
                    sensesChart
                    emotionChart
                    VStack(spacing: 23) {
                        levelsChart
                        contextChart
                    }
                    libraryProgress
                    revisitSummary
                    HStack(spacing: 7) {
                        Image(systemName: "lock.shield")
                        Text("Calculated on this device from your notes.")
                    }.font(.caption2).foregroundColor(Palette.secondary).frame(maxWidth: .infinity).padding(.vertical, 5)
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .pageBackground().navigationTitle("Insights").navigationBarTitleDisplayMode(.inline)
            .onChange(of: range) { _ in selectedBucket = nil }
            .onChange(of: fieldbookID) { _ in selectedBucket = nil }
            .onChange(of: store.fieldbooks) { books in if let id = fieldbookID, !books.contains(where: { $0.id == id }) { fieldbookID = nil } }
            .sheet(item: $composer) { ComposerSheet(request: $0) }
            .sheet(item: $collection) { item in
                NavigationView {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            if collectionNotes(item).isEmpty {
                                EmptyState(symbol: item.onlyLoose ? "checkmark.circle" : "book.closed", title: item.onlyLoose ? "No loose pages left in this view" : "No notes in this view", message: item.onlyLoose ? "Your changes are saved. Return to Insights to see your updated fieldbook totals." : "Choose another period or fieldbook, or keep a new moment from Today.")
                            }
                            ForEach(collectionNotes(item)) { entry in
                                NavigationLink { EntryDetailView(entryID: entry.id) } label: { EntryCard(entry: entry) }.buttonStyle(.plain)
                            }
                        }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
                    }.pageBackground().navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { collection = nil } } }
                }.navigationViewStyle(.stack)
            }
        }.navigationViewStyle(.stack)
    }

    private func collectionNotes(_ item: NoteCollection) -> [JournalEntry] {
        store.entries.filter { item.entryIDs.contains($0.id) && (!item.onlyLoose || $0.fieldbookIDs.isEmpty) }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("The shape of your days.").font(.system(size: 29, weight: .regular, design: .serif)).foregroundColor(Palette.text)
                    Text("Follow the details back to their pages.").font(.subheadline).foregroundColor(Palette.secondary)
                }
                Spacer(minLength: 0)
                BrandMark(size: 43)
            }
            Menu {
                Button("Whole journal") { fieldbookID = nil }
                ForEach(store.fieldbooks) { book in
                    Button { fieldbookID = book.id } label: { Label(book.name + (book.isArchived ? " · Archived" : ""), systemImage: fieldbookID == book.id ? "checkmark.circle.fill" : book.symbol) }
                }
            } label: {
                HStack {
                    Image(systemName: "books.vertical")
                    Text(store.fieldbooks.first { $0.id == fieldbookID }?.name ?? "Whole journal").lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption)
                }.font(.subheadline.weight(.medium)).foregroundColor(Palette.sage).padding(15).background(JournalTone.sage.wash).clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Palette.sage.opacity(0.22), lineWidth: 1))
            }
            if !canCapture, let id = fieldbookID {
                NavigationLink { FieldbookDetailView(bookID: id) } label: { Label("Archived fieldbook · View details", systemImage: "archivebox").font(.caption) }
            }
        }
    }

    private var timeSelector: some View {
        HStack(spacing: 4) {
            ForEach(InsightRange.allCases, id: \.self) { item in
                Button { range = item } label: {
                    Text(item.rawValue).font(.system(.caption, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                        .foregroundColor(range == item ? .white : Palette.secondary)
                        .background {
                            if range == item { JournalTone.honey.gradient } else { Color.clear }
                        }.clipShape(RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).accessibilityAddTraits(range == item ? .isSelected : [])
            }
        }.padding(5).background(JournalTone.honey.wash).clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private var overview: some View {
        HStack(alignment: .top, spacing: 10) {
            Button { collection = NoteCollection(title: "Kept moments", entryIDs: entries.map(\.id)) } label: {
                StatTile(value: "\(entries.count)", title: "Kept moments", symbol: "book.closed")
            }.buttonStyle(.plain).disabled(entries.isEmpty)
            StatTile(value: "\(activeDays)", title: "Recorded days", symbol: "calendar", color: Palette.sage)
            Button { collection = NoteCollection(title: "Revisit notes", entryIDs: entries.filter { $0.revisitTaskID != nil }.map(\.id)) } label: {
                StatTile(value: "\(entries.filter { $0.revisitTaskID != nil }.count)", title: "Revisit notes", symbol: "arrow.triangle.2.circlepath", color: Palette.gold)
            }.buttonStyle(.plain).disabled(!entries.contains { $0.revisitTaskID != nil })
        }
    }

    @ViewBuilder private var periodComparison: some View {
        if let days = range.days {
            let difference = entries.count - previousEntries.count
            HStack(alignment: .top, spacing: 10) {
                IconBadge(symbol: "rectangle.split.2x1", color: Palette.gold, size: 32)
                VStack(alignment: .leading, spacing: 5) {
                    Text(difference == 0 ? "The same number of notes" : "\(abs(difference)) \(difference > 0 ? "more" : "fewer") \(abs(difference) == 1 ? "note" : "notes")")
                        .font(.subheadline.weight(.medium)).foregroundColor(Palette.text)
                    Text("\(entries.count) now · \(previousEntries.count) in the same span \(days) days earlier").font(.caption).foregroundColor(Palette.secondary)
                    if !previousEntries.isEmpty {
                        Button("Open the earlier notes") { collection = NoteCollection(title: "Earlier period", entryIDs: previousEntries.map(\.id)) }.font(.caption.weight(.medium))
                    }
                }
                Spacer(minLength: 0)
            }.surface(padding: 15, tint: Palette.gold)
        }
    }

    private var activityChart: some View {
        let data = buckets
        let maximum = max(1, data.map { $0.entries.count }.max() ?? 1)
        let current = data.first { $0.date == selectedBucket } ?? data.last
        return VStack(alignment: .leading, spacing: 19) {
            HStack(alignment: .top) {
                SectionHeading(title: "Pages over time", subtitle: "Tap a column, then open its notes.")
                IconBadge(symbol: "chart.bar.fill", size: 34)
            }
            HStack(spacing: 17) { legend("Sensory", color: Palette.accent); legend("Emotion", color: Palette.plum) }
            ZStack(alignment: .bottom) {
                VStack {
                    ForEach(0..<4) { _ in Rectangle().fill(Palette.line).frame(height: 1); Spacer(minLength: 0) }
                    Rectangle().fill(Palette.line).frame(height: 1)
                }.frame(height: 135).padding(.bottom, 22).accessibilityHidden(true)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, bucket in
                        Button { selectedBucket = bucket.date } label: {
                            VStack(spacing: 8) {
                                VStack(spacing: 3) {
                                    Spacer(minLength: 0)
                                    if !bucket.entries.isEmpty { Text("\(bucket.entries.count)").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(Palette.secondary) }
                                    if bucket.emotion > 0 { RoundedRectangle(cornerRadius: 4).fill(JournalTone.lavender.gradient).frame(height: max(3, 108 * CGFloat(bucket.emotion) / CGFloat(maximum))) }
                                    if bucket.sensory > 0 { RoundedRectangle(cornerRadius: 4).fill(JournalTone.clay.gradient).frame(height: max(3, 108 * CGFloat(bucket.sensory) / CGFloat(maximum))) }
                                    if bucket.entries.isEmpty { RoundedRectangle(cornerRadius: 4).fill(Palette.line).frame(height: 4) }
                                }.frame(height: 135)
                                    .opacity(selectedBucket == nil || selectedBucket == bucket.date ? 1 : 0.4)
                                Text(axisLabel(bucket.date, index: index, count: data.count)).font(.system(size: 8, weight: .medium)).foregroundColor(Palette.secondary).lineLimit(1).frame(height: 14)
                            }.frame(maxWidth: .infinity)
                        }.buttonStyle(.plain).accessibilityLabel("\(bucketLabel(bucket)), \(bucket.sensory) sensory notes, \(bucket.emotion) emotion notes")
                    }
                }
            }
            if let current = current {
                HStack {
                    Text(bucketLabel(current)).font(.caption).foregroundColor(Palette.secondary)
                    Spacer()
                    Text("\(current.entries.count) \(current.entries.count == 1 ? "note" : "notes")").font(.caption.weight(.semibold)).foregroundColor(Palette.text)
                }
                if !current.entries.isEmpty {
                    Button {
                        collection = NoteCollection(title: bucketLabel(current), entryIDs: current.entries.map(\.id))
                    } label: { Label("Open these notes", systemImage: "arrow.up.right").font(.caption.weight(.medium)) }
                }
            }
        }.surface(tint: Palette.accent)
    }

    private var sensesChart: some View {
        VStack(alignment: .leading, spacing: 19) {
            SectionHeading(title: "Your sensory pages", subtitle: "Each axis shows the share of sensory notes using that sense.")
            if sensory.isEmpty {
                chartEmpty("Add a sensory note to see your senses here.", symbol: "sparkles")
                Button { composer = .new(kind: .sensory, book: store.fieldbooks.first { $0.id == fieldbookID }) } label: { Label("Keep a sensory moment", systemImage: "plus") }.buttonStyle(QuietButtonStyle()).disabled(!canCapture)
            } else {
                SensoryCompass(counts: Dictionary(uniqueKeysWithValues: Sense.allCases.map { sense in (sense, sensory.filter { $0.senses.contains(sense) }.count) }), total: sensory.count) { sense in
                    collection = NoteCollection(title: sense.title, entryIDs: sensory.filter { $0.senses.contains(sense) }.map(\.id))
                }
                ForEach(Sense.allCases) { sense in
                    let count = sensory.filter { $0.senses.contains(sense) }.count
                    Button {
                        collection = NoteCollection(title: sense.title, entryIDs: sensory.filter { $0.senses.contains(sense) }.map(\.id))
                    } label: {
                        distributionRow(title: sense.title, symbol: sense.symbol, color: sense.tint, count: count, maximum: max(1, sensory.count))
                    }.buttonStyle(.plain).disabled(count == 0)
                }
                Text("A note can include more than one sense.").font(.caption2).foregroundColor(Palette.secondary)
            }
        }.surface(tint: Palette.sage)
    }

    private var emotionChart: some View {
        VStack(alignment: .leading, spacing: 19) {
            SectionHeading(title: "The feelings you named", subtitle: "How often each of your labels appears.")
            if tagCounts.isEmpty {
                chartEmpty("Your emotion labels will appear as you use them.", symbol: "heart.text.square")
                Button { composer = .new(kind: .emotion, book: store.fieldbooks.first { $0.id == fieldbookID }) } label: { Label("Keep an emotion note", systemImage: "plus") }.buttonStyle(QuietButtonStyle(tone: .lavender)).disabled(!canCapture)
            } else {
                ForEach(tagCounts, id: \.tag.id) { item in
                    Button {
                        collection = NoteCollection(title: item.tag.name, entryIDs: emotions.filter { $0.emotionTagIDs.contains(item.tag.id) }.map(\.id))
                    } label: {
                        distributionRow(title: item.tag.name, symbol: item.tag.symbol, color: Color(hex: item.tag.colorHex), count: item.count, maximum: max(1, emotions.count))
                    }.buttonStyle(.plain)
                }
                Text("Multiple labels can belong to the same note. Tap a row to browse.").font(.caption2).foregroundColor(Palette.secondary)
            }
        }.surface(tint: Palette.plum)
    }

    private var levelsChart: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeading(title: "Your recorded levels", subtitle: "The intensity and energy you chose, from 1 to 5.")
            if emotions.isEmpty {
                chartEmpty("Record an emotion note to start this chart.", symbol: "waveform.path")
            } else {
                HStack(spacing: 22) {
                    averageLabel("Avg. intensity", value: Double(emotions.map(\.intensity).reduce(0, +)) / Double(emotions.count), color: Palette.plum)
                    averageLabel("Avg. energy", value: Double(emotions.map(\.energy).reduce(0, +)) / Double(emotions.count), color: Palette.sage)
                }
                LevelsPlot(intensity: buckets.map(\.intensity), energy: buckets.map(\.energy))
                    .frame(height: 135)
                HStack {
                    Text(EnglishDate.string(start, template: "MMM d"))
                    Spacer()
                    Text(EnglishDate.string(Date(), template: "MMM d"))
                }.font(.caption2).foregroundColor(Palette.secondary)
                HStack(spacing: 17) { legend("Intensity", color: Palette.plum); legend("Energy", color: Palette.sage) }
                Text("Values are averaged within each time interval. Intervals without notes are left blank.").font(.caption2).foregroundColor(Palette.secondary)
                DisclosureGroup("View recorded values") {
                    VStack(spacing: 12) {
                        HStack { Text("Interval"); Spacer(); Text("Intensity / Energy") }.font(.caption2).foregroundColor(Palette.secondary)
                        ForEach(buckets.filter { !$0.emotionEntries.isEmpty }) { bucket in
                            HStack {
                                Text(bucketLabel(bucket)).font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", bucket.intensity ?? 0)) / \(String(format: "%.1f", bucket.energy ?? 0))").font(.caption.monospacedDigit())
                            }.foregroundColor(Palette.text)
                        }
                    }.padding(.top, 14)
                }.font(.caption.weight(.medium))
            }
        }.surface(tint: Palette.plum)
    }

    private var libraryProgress: some View {
        let filed = entries.filter { !$0.fieldbookIDs.isEmpty }.count
        let loose = entries.filter { $0.fieldbookIDs.isEmpty }
        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 17) {
                ZStack {
                    Circle().stroke(Palette.line, lineWidth: 6)
                    Circle().trim(from: 0, to: CGFloat(filed) / CGFloat(max(1, entries.count))).stroke(Palette.sage, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                    Image(systemName: "books.vertical").font(.title3).foregroundColor(Palette.sage)
                }.frame(width: 55, height: 55).accessibilityHidden(true)
                SectionHeading(title: "A home for your pages", subtitle: "\(filed) of \(entries.count) notes filed in a fieldbook.")
            }
            HStack(spacing: 15) {
                Label("\(entries.flatMap(\.photoIDs).count) photos", systemImage: "photo")
                Label("\(entries.filter { !store.linkedEntries(for: $0).isEmpty }.count) connected notes", systemImage: "link")
            }.font(.caption).foregroundColor(Palette.secondary)
            if !loose.isEmpty {
                Button { collection = NoteCollection(title: "Loose pages", entryIDs: loose.map(\.id), onlyLoose: true) } label: { Label("Find loose pages", systemImage: "tray") }.buttonStyle(QuietButtonStyle(tone: .sage))
            } else if !entries.isEmpty {
                Text("Every note in this view has a fieldbook.").font(.caption).foregroundColor(Palette.secondary)
            }
        }.surface(tint: Palette.sage)
    }

    private var revisitSummary: some View {
        let pending = store.pendingRevisits.filter { task in
            guard let source = store.entries.first(where: { $0.id == task.sourceEntryID }) else { return false }
            guard let id = fieldbookID else { return true }
            return source.fieldbookIDs.contains(id)
        }
        return NavigationLink { RevisitQueueView(fieldbookID: fieldbookID) } label: {
            HStack(spacing: 13) {
                IconBadge(symbol: "arrow.triangle.2.circlepath", color: Palette.gold)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Return to a detail").font(.system(.headline, design: .serif)).foregroundColor(Palette.text)
                    Text("\(pending.count) open \(pending.count == 1 ? "plan" : "plans") \(fieldbookID == nil ? "in your journal" : "in this fieldbook") · Any scheduled date").font(.caption).foregroundColor(Palette.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.caption).foregroundColor(Palette.gold)
            }.surface(tint: Palette.gold)
        }.buttonStyle(.plain)
    }

    private var contextChart: some View {
        let grouped = Dictionary(grouping: emotions.filter { !$0.context.trimmed.isEmpty }) { $0.context.trimmed.lowercased() }
        let keys = grouped.keys.sorted {
            let left = grouped[$0]?.count ?? 0
            let right = grouped[$1]?.count ?? 0
            return left == right ? $0 < $1 : left > right
        }
        return VStack(alignment: .leading, spacing: 19) {
            SectionHeading(title: "Places in your day", subtitle: "The contexts you added to emotion notes.")
            if keys.isEmpty {
                chartEmpty("Add a context like home, work, or outdoors to see it here.", symbol: "square.grid.2x2")
            } else {
                ForEach(Array(keys.prefix(8)), id: \.self) { key in
                    let notes = grouped[key] ?? []
                    Button {
                        collection = NoteCollection(title: notes.first?.context ?? key.capitalized, entryIDs: notes.map(\.id))
                    } label: {
                        distributionRow(title: notes.first?.context ?? key.capitalized, symbol: "circle.grid.2x2.fill", color: Palette.plum, count: notes.count, maximum: max(1, emotions.count))
                    }.buttonStyle(.plain)
                }
            }
        }.surface(tint: Palette.rose)
    }

    private func distributionRow(title: String, symbol: String, color: Color, count: Int, maximum: Int) -> some View {
        HStack(spacing: 12) {
            IconBadge(symbol: symbol, color: color, size: 32)
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(title).font(.subheadline).foregroundColor(Palette.text).lineLimit(2)
                    Spacer()
                    Text("\(count)").font(.system(.caption, design: .rounded).weight(.semibold)).foregroundColor(Palette.secondary)
                }
                GeometryReader { geometry in
                    Capsule().fill(Palette.line).overlay(alignment: .leading) {
                        Capsule().fill(LinearGradient(colors: [color.opacity(0.60), color], startPoint: .leading, endPoint: .trailing)).frame(width: geometry.size.width * CGFloat(count) / CGFloat(maximum))
                    }
                }.frame(height: 5)
            }
        }.accessibilityElement(children: .combine)
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 5) { Circle().fill(color).frame(width: 6, height: 6); Text(title).font(.caption2).foregroundColor(Palette.secondary) }
    }

    private func chartEmpty(_ message: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol).foregroundColor(Palette.accent.opacity(0.65))
            Text(message).font(.subheadline).foregroundColor(Palette.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 17)
    }

    private func averageLabel(_ title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(String(format: "%.1f", value)).font(.system(size: 28, weight: .semibold, design: .rounded)).foregroundColor(color)
            Text(title).font(.caption2).foregroundColor(Palette.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func axisLabel(_ date: Date, index: Int, count: Int) -> String {
        if count > 7 && index % 2 != 0 && index != count - 1 { return "" }
        return EnglishDate.string(date, template: range == .week ? "EEE" : "M/d")
    }

    private func bucketLabel(_ bucket: ActivityBucket) -> String {
        let last = Calendar.current.date(byAdding: .day, value: -1, to: bucket.end)!
        if Calendar.current.isDate(bucket.date, inSameDayAs: last) { return EnglishDate.string(bucket.date, template: "MMM d") }
        return "\(EnglishDate.string(bucket.date, template: "MMM d")) – \(EnglishDate.string(last, template: "MMM d"))"
    }
}

private struct LevelsPlot: View {
    let intensity: [Double?]
    let energy: [Double?]
    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width - 23)
            let height = max(1, geometry.size.height - 18)
            ZStack(alignment: .topLeading) {
                ForEach([1, 3, 5], id: \.self) { level in
                    HStack(spacing: 7) {
                        Text("\(level)").font(.system(size: 9)).foregroundColor(Palette.secondary).frame(width: 12)
                        Rectangle().fill(Palette.line).frame(height: 1)
                    }.position(x: geometry.size.width / 2, y: 8 + height * (1 - CGFloat(level - 1) / 4))
                }
                line(intensity, width: width, height: height).stroke(Palette.plum, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)).offset(x: 23, y: 8)
                line(energy, width: width, height: height).stroke(Palette.sage, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)).offset(x: 23, y: 8)
                dots(intensity, color: Palette.plum, width: width, height: height)
                dots(energy, color: Palette.sage, width: width, height: height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recorded emotion levels chart. \(intensity.compactMap { $0 }.count) time intervals contain notes. Intensity and energy range from 1 to 5.")
    }

    private func point(_ index: Int, value: Double, count: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        CGPoint(x: count == 1 ? width / 2 : CGFloat(index) / CGFloat(max(1, count - 1)) * width, y: height * (1 - CGFloat(value - 1) / 4))
    }

    private func line(_ values: [Double?], width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            var previous = false
            for (index, value) in values.enumerated() {
                guard let value = value else { previous = false; continue }
                let p = point(index, value: value, count: values.count, width: width, height: height)
                if previous { path.addLine(to: p) } else { path.move(to: p) }
                previous = true
            }
        }
    }

    private func dots(_ values: [Double?], color: Color, width: CGFloat, height: CGFloat) -> some View {
        ForEach(values.indices, id: \.self) { index in
            if let value = values[index] {
                let p = point(index, value: value, count: values.count, width: width, height: height)
                Circle().fill(color).frame(width: 6, height: 6).position(x: p.x + 23, y: p.y + 8)
            }
        }
    }
}
