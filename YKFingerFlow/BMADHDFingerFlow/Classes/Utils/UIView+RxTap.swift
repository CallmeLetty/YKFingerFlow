import RxCocoa
import RxSwift
import UIKit

extension Reactive where Base: UIView {
  /// Adds a tap gesture recognizer to the view and exposes its events.
  func tapGesture() -> ControlEvent<UITapGestureRecognizer> {
    let gesture = UITapGestureRecognizer()
    base.isUserInteractionEnabled = true
    base.addGestureRecognizer(gesture)
    return gesture.rx.event
  }
}

extension ControlEvent where Element: UIGestureRecognizer {
  func when(_ state: UIGestureRecognizer.State) -> ControlEvent<Element> {
    ControlEvent(events: asObservable().filter { gesture in
      gesture.state == state || (state == .recognized && gesture.state == .ended)
    })
  }
}
