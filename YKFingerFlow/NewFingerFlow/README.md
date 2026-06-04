# NewFingerFlow

Refactored FingerFlow implementation (P0–P3). **Legacy `FingerFlow` sources are not modified.**

## Integration

```swift
navigationController?.pushViewController(NewFingerFlowViewController(), animated: true)
```

Optional: add a second button on the host `ViewController` that pushes `NewFingerFlowViewController` instead of `FingerFlowVC`.

## Layout

| Folder | Responsibility |
|--------|----------------|
| `Core/` | Types, reducer (P2), path builder, `CGPath` sampling |
| `Clock/` | Master display-link clock (P1), async countdown |
| `Animation/` | Guide loop (P0+P3), prompt property animators |
| `View/` | Game surface, pause overlay |
| `ViewController/` | Effect runner wiring |

## Tech share

See [TECH_SHARE_COMPARISON.md](./TECH_SHARE_COMPARISON.md).
