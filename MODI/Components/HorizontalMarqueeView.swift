import SwiftUI

// MARK: - HorizontalMarqueeView

/// 오른쪽에서 왼쪽으로 일정 속도로 흐르는 1행 무한 마키 뷰입니다.
struct HorizontalMarqueeView<Item, Content: View>: View {

    let items: [Item]
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    let spacing: CGFloat
    let speed: CGFloat
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let layout = HorizontalMarqueeLayout.periodTile(
                from: items,
                itemWidth: { _ in itemWidth },
                spacing: spacing,
                minimumWidth: viewportWidth
            )
            let repeatCount = HorizontalMarqueeLayout.tileRepeatCount(
                viewportWidth: viewportWidth,
                loopPeriod: layout.loopPeriod
            )

            TimelineView(.animation) { timeline in
                let scrollOffset = scrollOffset(at: timeline.date, loopPeriod: layout.loopPeriod)
                let originX = HorizontalMarqueeLayout.originX(
                    scrollOffset: scrollOffset,
                    loopPeriod: layout.loopPeriod
                )

                HStack(spacing: spacing) {
                    ForEach(0..<repeatCount, id: \.self) { tileIndex in
                        ForEach(Array(layout.tile.enumerated()), id: \.offset) { itemIndex, item in
                            content(item)
                                .id("\(tileIndex)-\(itemIndex)")
                        }
                    }
                }
                .offset(x: originX)
            }
        }
        .frame(height: itemHeight)
        .clipped()
    }

    private func scrollOffset(at date: Date, loopPeriod: CGFloat) -> CGFloat {
        guard loopPeriod > 0, speed > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate
        return CGFloat(elapsed * speed).truncatingRemainder(dividingBy: loopPeriod)
    }
}
