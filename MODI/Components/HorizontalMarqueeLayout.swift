import CoreGraphics

// MARK: - HorizontalMarqueeLayout

/// 가로 무한 마키의 1주기 타일 너비와 반복 시퀀스를 계산합니다.
enum HorizontalMarqueeLayout {

    static func contentWidth<Item>(
        items: [Item],
        itemWidth: (Item) -> CGFloat,
        spacing: CGFloat
    ) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        let widths = items.reduce(CGFloat.zero) { $0 + itemWidth($1) }
        let gaps = spacing * CGFloat(items.count - 1)
        return widths + gaps
    }

    /// 컬렉션 순서를 유지한 채 `minimumWidth` 이상이 될 때까지 아이템을 반복합니다.
    static func repeatedItems<Item>(
        _ items: [Item],
        itemWidth: (Item) -> CGFloat,
        spacing: CGFloat,
        minimumWidth: CGFloat
    ) -> [Item] {
        guard !items.isEmpty else { return [] }

        var result: [Item] = []
        while contentWidth(items: result, itemWidth: itemWidth, spacing: spacing) < minimumWidth {
            result.append(contentsOf: items)
        }
        return result
    }

    /// 화면을 채울 만큼 반복한 1주기 타일과 루프 주기를 반환합니다.
    static func periodTile<Item>(
        from items: [Item],
        itemWidth: (Item) -> CGFloat,
        spacing: CGFloat,
        minimumWidth: CGFloat
    ) -> (tile: [Item], loopPeriod: CGFloat) {
        guard !items.isEmpty else { return ([], 0) }

        let requiredWidth = max(minimumWidth, contentWidth(items: items, itemWidth: itemWidth, spacing: spacing))
        let tile = repeatedItems(items, itemWidth: itemWidth, spacing: spacing, minimumWidth: requiredWidth)
        let loopPeriod = max(contentWidth(items: tile, itemWidth: itemWidth, spacing: spacing), 1)
        return (tile, loopPeriod)
    }

    /// 스크롤 오프셋에 맞춰 타일 시작 X 좌표를 계산합니다. 뷰포트 좌측이 비지 않도록 합니다.
    static func originX(scrollOffset: CGFloat, loopPeriod: CGFloat) -> CGFloat {
        guard loopPeriod > 0 else { return 0 }

        let normalizedOffset = scrollOffset.truncatingRemainder(dividingBy: loopPeriod)
        var originX = -normalizedOffset

        while originX > 0 {
            originX -= loopPeriod
        }

        return originX
    }

    /// 뷰포트를 끊김 없이 채우기 위해 필요한 타일 반복 횟수입니다.
    static func tileRepeatCount(viewportWidth: CGFloat, loopPeriod: CGFloat) -> Int {
        guard loopPeriod > 0 else { return 1 }
        return max(2, Int(ceil((viewportWidth + loopPeriod) / loopPeriod)) + 1)
    }
}

// MARK: - MarqueeScrollSpeed

enum MarqueeScrollSpeed {
    /// 공유 영상 생성 마키 속도 (pt/s)
    static let shareVideo: CGFloat = 160
    /// 홈 화면 오늘의 컬렉션 마키 속도 (pt/s)
    static let homeCollection: CGFloat = 44
}
