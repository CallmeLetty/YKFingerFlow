// Copyright (c) 2026, YKFingerFlow — 带解析弧长的种子路径生成（仅 New）。

import UIKit

enum NewFingerFlowSubPathGenerator {
  /// 单次生成失败时最多重试次数（每次用 seed + attempt 换随机序列）
  private static let maxAttempts = 32
  /// 每段弧的转角候选（度）；出界时会改用 330° 大弯
  private static let angleOptions: [CGFloat] = [180, 210, 240, 270, 300]
  /// 每段弧的半径候选（屏宽比例）→ 弯有大有小
  private static let radiusOptions: [CGFloat] = [
    FrameGuide.screenWidth / 4,
    FrameGuide.screenWidth / 3,
    FrameGuide.screenWidth / 10,
    FrameGuide.screenWidth / 12,
  ]

  /// 负责在屏幕安全区内，用一串随机圆弧拼出一条长度刚好够的弯路线
  /// - Parameters:
  ///   - startPath: 已有的起始弧（120°），链从这里接着画
  ///   - startCenter: 起始弧的圆心
  ///   - wholeLengthWithoutStart: 还要画多长 = 时长 × 15 pt（不含起始弧）
  ///   - pointSafeArea: 圆点能活动的矩形区域（比屏幕小一圈，留出圆点半径）
  ///   - seed: 随机种子（见下方「seed 是什么」）；同 seed 且同一次 attempt → 同一条路
  /// - Returns: 每一段都是一段圆弧；拼到 startPath 后面就是完整游戏路径。
  ///
  /// `generate` 只负责重试调度；真正一段段画弧的逻辑在 `attemptGenerate`。
  /// 本局 seed 来自 Reducer 的 `pathGeneration`（每开一局 `&+ 1`），传入 `rebuildPath`。
  static func generate(
    startPath: UIBezierPath,
    startCenter: CGPoint,
    wholeLengthWithoutStart: CGFloat,
    pointSafeArea: CGRect,
    seed: UInt64
  ) -> [UIBezierPath]? {
    // 几何偶发失败（NaN 等）时用 seed+attempt 换一套随机数重试；全失败则 PathBuilder 回退 Legacy subPaths
    for attempt in 0..<maxAttempts {
      // seed 决定「掷骰子」的起手；attempt 只在失败时微调，成功路径仍主要由 seed 决定
      var rng = SeededRNG(seed: seed &+ UInt64(attempt))
      if let paths = attemptGenerate(
        startPath: startPath,
        startCenter: startCenter,
        wholeLengthWithoutStart: wholeLengthWithoutStart,
        pointSafeArea: pointSafeArea,
        rng: &rng
      ) {
        return paths
      }
    }
    return nil
  }

  /// 单次尝试：从 `startPath` 终点开始接龙画弧，直到累计长度达到 `wholeLengthWithoutStart`。
  /// 每一步循环：随机半径与转角 → 算圆心 → 越界则缩半径 → 必要时末段裁角度 → 追加一段 `UIBezierPath`。
  /// 几何非法（终点 NaN）时返回 `nil`，由外层 `generate` 换 `seed + attempt` 重试。
  ///
  /// - Parameter rng: 随机数发生器（RNG），本方法内所有「随机选半径/角度」都通过它取值；
  ///   传入 `inout` 是因为每取一次随机数内部状态会前进，下次取值才不一样。
  private static func attemptGenerate(
    startPath: UIBezierPath,
    startCenter: CGPoint,
    wholeLengthWithoutStart: CGFloat,
    pointSafeArea: CGRect,
    rng: inout SeededRNG
  ) -> [UIBezierPath]? {
    var result = [UIBezierPath]()
    var tempPath = startPath
    var clockwise = true
    var previousCenter = startCenter
    var currentLength: CGFloat = 0

    // 接龙画弧：累计长度达到预算（时长×15）为止
    while currentLength < wholeLengthWithoutStart {
      let segmentStart = tempPath.currentPoint
      // 掷骰子：随机半径，方向每段交替顺/逆时针（蛇形左右拐）
      var radius = radiusOptions.random(using: &rng) ?? radiusOptions[0]
      clockwise.toggle()

      // 根据上一段圆心 + 当前切点 + 新半径，几何算出本段圆心
      var fitsSafeArea = true
      var center = previousCenter.calDestination(pastPoint: segmentStart, nextRadius: radius)
      // 圆弧超出安全区则半径减半重算，直到能放下
      while !pointSafeArea.rangeJudgeLegal(center: center, radius: radius) {
        fitsSafeArea = false
        radius /= 2
        center = previousCenter.calDestination(pastPoint: segmentStart, nextRadius: radius)
      }

      let remaining = wholeLengthWithoutStart - currentLength
      // 正常随机转角；若曾缩半径说明空间紧，改用 330° 大弯绕回
      let fullAngle = fitsSafeArea ? (angleOptions.random(using: &rng) ?? 240) : 330
      // 解析弧长（不用 cgPath.length 折线近似）
      let segmentLength = radius * fullAngle / 180 * .pi

      let angle: CGFloat
      if currentLength + segmentLength > wholeLengthWithoutStart {
        // 末段裁切：只画够剩余预算的角度，不整段重掷（对齐 Legacy 手感、长度更准）
        angle = max(remaining / radius * 180 / .pi, 1)
      } else {
        angle = fullAngle
      }

      let path = UIBezierPath(
        start: segmentStart,
        center: center,
        radius: radius,
        clockWise: clockwise,
        angle: angle
      )

      if path.currentPoint.x.isNaN {
        return nil // 本 attempt 作废，外层换 seed+attempt 重试
      }

      let actualLength = radius * angle / 180 * .pi
      result.append(path)
      currentLength += actualLength
      tempPath = path
      previousCenter = center

      if currentLength >= wholeLengthWithoutStart {
        break // 预算已满，末段可能已裁切
      }
    }

    return result
  }
}

// MARK: - 带种子的随机数（RNG）
//
// RNG = Random Number Generator，随机数发生器。
// 路径里每一段的半径、转角看起来随机，实际由 RNG 按固定公式一串一串算出来。
//
// seed（种子）= 一个 UInt64 整数，用来初始化 RNG 的内部状态。
// - 种子相同 → 后面掷出的随机数序列相同 → 生成的弯路线完全相同（方便复现 bug、写单测）。
// - 种子不同 → 路线不同。
// Legacy 用 `Int.random()`，每次运行都不同且无法指定；New 用 `SeededRNG(seed:)` 替代。
//
// 本局种子存在 `snapshot.pathGeneration`，进入 running 时 `rebuildPath(seed: pathGeneration &+ 1, …)`。

/// 可复现的伪随机发生器；实现 Swift `RandomNumberGenerator`，供 `Int.random(using:)` 等使用。
struct SeededRNG: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed // 0 视为非法种子，换默认常量
  }

  /// 产出下一个伪随机 UInt64；每次调用都会推进 `state`，故须 `mutating`。
  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

private extension Array where Element == CGFloat {
  /// 用 RNG 从数组里随机挑一个 CGFloat（半径或角度候选）
  func random(using rng: inout SeededRNG) -> CGFloat? {
    guard !isEmpty else { return nil }
    let index = Int.random(in: 0..<count, using: &rng)
    return self[index]
  }
}
