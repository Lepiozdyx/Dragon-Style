import UIKit

extension Int {
    private var designSize: CGSize { CGSize(width: 375, height: 812) }

    private var maxScale: CGFloat { 1.20 }
    private var minScale: CGFloat { 0.90 }

    private var ipadMaxContentWidthForScaling: CGFloat { 600 }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var screenBounds: CGRect { UIScreen.main.bounds }
    private var screenSize: CGSize { screenBounds.size }

    private var usableWidth: CGFloat {
        if let window = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window.bounds.width - (window.safeAreaInsets.left + window.safeAreaInsets.right)
        }
        return screenSize.width
    }

    private var effectiveWidthForScale: CGFloat {
        if isPad {
            return Swift.min(usableWidth, ipadMaxContentWidthForScaling)
        } else {
            return usableWidth
        }
    }

    private func clampedScale(_ raw: CGFloat) -> CGFloat {
        Swift.max(minScale, Swift.min(maxScale, raw))
    }

    private var widthScale: CGFloat {
        clampedScale(effectiveWidthForScale / designSize.width)
    }

    private var heightScale: CGFloat {
        if isPad {
            return widthScale
        } else {
            return clampedScale(screenSize.height / designSize.height)
        }
    }

    var fitW: CGFloat { CGFloat(self) * widthScale }
    var fitH: CGFloat { CGFloat(self) * heightScale }

    var fitWMore: CGFloat {
        let conditionWidth = isPad ? effectiveWidthForScale : screenSize.width
        return conditionWidth > designSize.width ? fitW : CGFloat(self)
    }

    var fitHMore: CGFloat {
        let refHeight = screenSize.height
        return refHeight > designSize.height ? fitH : CGFloat(self)
    }

    var fitWLess: CGFloat {
        let conditionWidth = isPad ? effectiveWidthForScale : screenSize.width
        return conditionWidth < designSize.width ? fitW : CGFloat(self)
    }

    var fitHLess: CGFloat {
        let refHeight = screenSize.height
        return refHeight < designSize.height ? fitH : CGFloat(self)
    }
}

extension CGFloat {
    private var designSize: CGSize { CGSize(width: 375, height: 812) }
    private var maxScale: CGFloat { 1.20 }
    private var minScale: CGFloat { 0.90 }
    private var ipadMaxContentWidthForScaling: CGFloat { 600 }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var screenBounds: CGRect { UIScreen.main.bounds }
    private var screenSize: CGSize { screenBounds.size }

    private var usableWidth: CGFloat {
        if let window = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window.bounds.width - (window.safeAreaInsets.left + window.safeAreaInsets.right)
        }
        return screenSize.width
    }

    private var effectiveWidthForScale: CGFloat {
        if isPad {
            return Swift.min(usableWidth, ipadMaxContentWidthForScaling)
        } else {
            return usableWidth
        }
    }

    private func clampedScale(_ raw: CGFloat) -> CGFloat {
        Swift.max(minScale, Swift.min(maxScale, raw))
    }

    private var widthScale: CGFloat {
        clampedScale(effectiveWidthForScale / designSize.width)
    }

    private var heightScale: CGFloat {
        if isPad {
            return widthScale
        } else {
            return clampedScale(screenSize.height / designSize.height)
        }
    }

    var fitW: CGFloat { self * widthScale }
    var fitH: CGFloat { self * heightScale }

    var fitWMore: CGFloat {
        let conditionWidth = isPad ? effectiveWidthForScale : screenSize.width
        return conditionWidth > designSize.width ? fitW : self
    }

    var fitHMore: CGFloat {
        let refHeight = screenSize.height
        return refHeight > designSize.height ? fitH : self
    }

    var fitWLess: CGFloat {
        let conditionWidth = isPad ? effectiveWidthForScale : screenSize.width
        return conditionWidth < designSize.width ? fitW : self
    }

    var fitHLess: CGFloat {
        let refHeight = screenSize.height
        return refHeight < designSize.height ? fitH : self
    }
}
