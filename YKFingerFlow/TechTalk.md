# FingerFlow 技术分享：几何与公式

> 只讲路径怎么画、弧长怎么算、时间怎么换成坐标。  
> 人话版：[DesignStory.md](DesignStory.md) · 实现对照：[Optimization.md](Optimization.md)

原设计：[交互篇](https://juejin.cn/post/7293723900588654644) · [算法篇](https://juejin.cn/post/7244840680383365177)

---

## 0. 要解决的三件事

1. **路径够长**：总弧长 ≈ `用户秒数 × 15`（pt）
2. **圆点匀速**：沿路径走，弯急弯缓速度一致（按**路程**均匀，不是按方程参数均匀）
3. **跟手判定**：手指离圆心 ≤ 55pt

---

## 1. 路径由什么拼成？

```
完整路径 = 起始弧（120°）+ 一串随机圆弧（接龙）
```

### 1.1 起始弧

| 量 | 代码里 |
|----|--------|
| 起点 | `startPoint`，约在 (80, 517/628) |
| 圆心 | `startCenter`，在起点右侧 |
| 半径 | `startRadius = 80 × 1.5 / π` |
| 扫角 | 120° |

弧长（解析，不用折线猜）：

```
L_start = startRadius × (120 / 180) × π
```

### 1.2 后面的圆弧链

每一段循环做这些事（`SubPathGenerator` / Legacy `subPaths`）：

1. 取上一段终点当切点 `segmentStart`
2. 随机半径 `r`（屏宽的 1/4、1/3、1/10、1/12 里挑）
3. 顺/逆时针交替
4. 用 `calDestination` 算新圆心（下一节）
5. 出安全区就 `r /= 2` 重算；实在不行画 330° 大弯
6. 弧长 `L_seg = r × (角度° / 180) × π`
7. 累加直到 ≥ `wholeLengthWithoutStart`

`wholeLengthWithoutStart` = `duration × 15`，**不含**起始弧那一段。

### 1.3 末段裁切（New 修正）

最后一段如果整弧画完会超预算，**只画够剩余长度对应的角度**：

```swift
// NewFingerFlowSubPathGenerator.swift
angle = max(remaining / radius * 180 / .pi, 1)
```

Legacy 超预算时有时仍 random 一整段，总长容易飘。

---

## 2. `calDestination`：下一段圆心怎么算？

输入：上一段圆心 `O_prev`、切点 `S`、新半径 `r_new`。

```
d = 距离(O_prev, S)    // 几何上 = 上一段半径

沿 O_prev → S 方向，把长度从 d 拉到 d + r_new，得到新圆心 O_new
```

代码用比例缩放偏移量（`FingerFlowExtension.calDestination`）：

```swift
xOffset2 = |S.x - O.x| × (d + r_new) / d
yOffset2 = |S.y - O.y| × (d + r_new) / d
// 再按象限决定加减
```

**为什么要这个**：两段圆弧在切点相切，路径不会折角断掉。

**安全区**：圆心 + 半径不能超出 `pointSafeArea`，否则半径减半重试。

---

## 3. 三种「进度」，别混

很多人栽在这里：以为有一个 `t` 从 0 走到 1 就完事。其实至少三套：

| 名字 | 是什么 | 用在哪 |
|------|--------|--------|
| **贝塞尔 t** | 曲线公式里的参数，0→1 按方程均匀 | 建弧长表时，把曲线拆成 24 段折线 |
| **弧长比例 s** | `已走距离 / 总距离`，0→1 | `point(atFraction:)`、`strokeStartFraction` |
| **时间进度 τ** | `elapsed / duration`（圆点用 `elapsed / dotDuration`） | `applyPlayback` 入口 |

换算关系（圆点）：

```
τ_dot = elapsed / dotDuration          // 时间走了百分之几
坐标  = arcLengthPath.point(atFraction: τ_dot)   // 把 τ 当弧长比例 s 去查表
```

**不能**把 `elapsed/duration` 直接塞进贝塞尔公式——弯急的地方方程 t 走得快，视觉上会忽快忽慢。

Legacy 让 `CAKeyframeAnimation` + `.paced` 在系统里做「时间 → 弧长」；New 用 knot 表自己查。

---

## 4. 弧长表：建一次，播放时查

### 4.1 构建（`NewFingerFlowArcLengthPath.make`）

沿 `CGPath` 走一遍。直线直接 `hypot`；曲线每段采 24 个点累加：

```
knots = [(累计弧长 L₀, 点 P₀), (L₁, P₁), …, (L_total, P_end)]
```

### 4.2 查询（`point(atFraction:hintIndex:)`）

输入 `s`（0~1 弧长比例）：

```
目标距离 L* = s × L_total
在 knots 里找到夹住 L* 的两点 (L_j, P_j)、(L_{j+1}, P_{j+1})
α = (L* - L_j) / (L_{j+1} - L_j)
返回 P_j + α × (P_{j+1} - P_j)
```

播放时 `hintIndex` 只往前扫，均摊接近 O(1)。

### 4.3 和 Legacy 差在哪

| | Legacy | New |
|---|--------|-----|
| 生成时算段长 | `cgPath.length`（24 段折线） | `r × θ × π/180` 直接算 |
| 播放时圆点位置 | CA `.paced` 黑盒 | knot 表查 |
| stroke 起点分母 | 目标 `duration×15` | 实际 `L_total` |

---

## 5. 播放：时间怎么变成画面

主时钟每帧给 `elapsed`（秒），用户选了 `duration = T`。

### 5.1 线（`strokeEnd`）

```swift
timeProgress = elapsed / T                    // 时间进度 τ_line
strokeFraction = strokeStart + (1 - strokeStart) × timeProgress
gameLayer.strokeEnd = strokeFraction
```

`strokeStart` = 起始 120° 弧占**整条路径实际长度**的比例：

```swift
// NewFingerFlowPathBuilder.swift
strokeStart = startArcLength / arcLengthPath.totalLength
```

### 5.2 圆点（`guideDot.center`）

圆点的时间轴比线**长一截**（对齐 Legacy 两个 CA 动画时长不同）：

```swift
dotDuration = duration + startArcLength / 15
dotT = elapsed / dotDuration
point = arcLengthPath.point(atFraction: dotT, hintIndex: &hintIndex)
guideDot.center = point
lastDotCenter = point   // 命中检测用同一坐标
```

`timeProgress`（线）和 `dotT`（点）**故意不相等**，不是 bug。

局末前 2 秒 `dotFrozen = true`，圆点停住，线还可以继续画（Legacy `stopDot`）。

---

## 6. 命中检测

```swift
hypot(触摸点.x - lastDotCenter.x, 触摸点.y - lastDotCenter.y) <= 55
```

`lastDotCenter` 就是上一帧查表结果，和屏幕上圆点位置同源。

Legacy 用 `presentation()?.frame.contains(触摸点)`——问渲染树，矩形判定，暂停/掉帧时可能对不上。

---

## 7. 整条几何管线

```
用户选 T 秒
  → L_need = T × 15
  → SubPathGenerator 接龙 + calDestination
  → CGPath
  → ArcLengthPath.make → knot 表
  → 每帧：elapsed → dotT → 查表得圆心
  → 长按：hypot(触摸, 圆心) ≤ 55
```

---

## 10. 代码在哪

| 内容 | 文件 |
|------|------|
| 圆心接龙 | `FingerFlowExtension.swift` → `calDestination` |
| 生成 + 裁切 | `NewFingerFlowSubPathGenerator.swift` |
| 弧长表 | `NewFingerFlowArcLengthPath.swift` |
| 时间→坐标 | `NewFingerFlowGameView.swift` → `applyPlayback` |
| stroke 起点 | `NewFingerFlowPathBuilder.swift` |

---

*路径：`YKFingerFlow/TechTalk.md`*
