import Foundation
import UIKit

extension UIScreen {
    static var isIphoneSEClassic: Bool {
        let size = main.bounds.size
        let aspect = max(size.width, size.height) / min(size.width, size.height)
        return abs(aspect - (568.0/320.0)) < 0.02
    }
}
