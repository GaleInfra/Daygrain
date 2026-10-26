import SwiftUI

struct SensoryCompass: View {
    let counts: [Sense: Int]
    let total: Int
    let onSelect: (Sense) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = side * 0.30
            ZStack {
                ForEach(1...3, id: \.self) { level in
                    polygon(center: center, radius: radius * CGFloat(level) / 3)
                        .stroke(Palette.line, style: StrokeStyle(lineWidth: 1, dash: level == 3 ? [] : [3, 4]))
                }
                ForEach(Array(Sense.allCases.enumerated()), id: \.element.id) { index, _ in
                    Path { path in path.move(to: center); path.addLine(to: point(index, center: center, radius: radius)) }
                        .stroke(Palette.line, lineWidth: 1)
                }
                dataPath(center: center, radius: radius).fill(LinearGradient(colors: [Palette.sage.opacity(0.24), Palette.gold.opacity(0.14), Palette.plum.opacity(0.23)], startPoint: .topLeading, endPoint: .bottomTrailing))
                dataPath(center: center, radius: radius).stroke(LinearGradient(colors: [Palette.sage, Palette.gold, Palette.plum], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                ForEach(Array(Sense.allCases.enumerated()), id: \.element.id) { index, sense in
                    let value = counts[sense] ?? 0
                    let position = point(index, center: center, radius: radius * CGFloat(value) / CGFloat(max(1, total)))
                    Circle().fill(sense.tint).frame(width: 7, height: 7).position(position).accessibilityHidden(true)
                    Button { onSelect(sense) } label: {
                        VStack(spacing: 4) {
                            Image(systemName: sense.symbol).font(.system(size: 16, weight: .medium))
                            Text("\(value)").font(.system(.caption, design: .rounded).weight(.semibold))
                        }.foregroundColor(sense.tint).frame(width: 48, height: 46)
                            .background(sense.tint.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 13))
                    }.buttonStyle(.plain).disabled(value == 0)
                        .position(point(index, center: center, radius: side * 0.405))
                        .accessibilityLabel("\(sense.title), \(value) of \(total) sensory notes. Open matching notes.")
                }
            }
        }.frame(height: 255)
    }

    private func point(_ index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = CGFloat(index) * .pi * 2 / 5 - .pi / 2
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
    private func polygon(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for index in 0..<5 {
                let p = point(index, center: center, radius: radius)
                if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }
    private func dataPath(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for (index, sense) in Sense.allCases.enumerated() {
                let ratio = CGFloat(counts[sense] ?? 0) / CGFloat(max(1, total))
                let p = point(index, center: center, radius: radius * ratio)
                if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }
}
