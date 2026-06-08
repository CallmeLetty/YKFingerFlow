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
| `Core/` | Types, reducer (P2), path builder, sub-path generator, arc-length table |
| `Clock/` | Master display-link clock (P1), async countdown |
| `Animation/` | Guide loop (P0+P3), prompt property animators |
| `View/` | Game surface, pause overlay |
| `ViewController/` | Effect runner wiring |

## Optimization

See [Optimization.md](../Optimization.md) for Legacy vs New algorithm and usage comparison.

## Design story

See [DesignStory.md](../DesignStory.md) for a narrative overview of the game design and refactor (Chinese).
