# FingerFlow

## 这游戏在玩什么？

用手指按住屏幕中央一颗发光的小圆点。三秒倒计时过后，跟随圆点沿着一条“**随机”弯曲轨迹**在屏幕上前行。

练习**专注力 + 耐心 + 微操稳定性。**

规则极简：

- **跟住它**。圆点动，手指也得动。
- **别松手，也别跑偏**。手指离圆心超过大约 **55pt**，游戏立刻暂停【New · `NewFingerFlowGameView.containsTouchNearGuide(_:threshold:)`，默认 55】
- **撑满选择的时长**。路径总长约 `时长 × 15` pt/s；跟完全程，看能坚持多久。【`speedPerSecond = 15` · Legacy `FingerFlowGameView` / New `NewFingerFlowPathLayout`】

```swift
// Legacy  FingerFlowGameView.swift
var lengthNeededToRun: Double { Double(duration) * speedPerSecond }  // speedPerSecond = 15

// New  NewFingerFlowPathBuilder.swift
let lengthNeeded = CGFloat(duration * speedPerSecond)
```

开局前会选挑战时长、背景图、BGM。  
长按圆心 **3 秒**启动【Legacy `startPreparation` · New `beginPreparationUI` → `startPreparationCountdown()`】；

中途暂停后，文案会变成「手指长按发光圆心**继续**」【`FingerFlowPropmptType.pausePlace`】。

中间偶尔蹦出「做得好！继续加油！」等鼓励。【Legacy `FingerFlowVC+Game.gameTimerAction` 每 15s · New `NewFingerFlowReducer.handleClockTick`，`welldoneInterval = 15`】

---

## 路径计算

路径不是设计师手绘的，是算法「掷骰子」掷出来的：

1. **起手式**：圆心先画一段约 **120°** 的起始弧，把手指从静止「拽」进轨道。【`NewFingerFlowPathLayout.make()`，`angle: 120`】
2. **随机链**：后面接一串随机半径、随机角度的圆弧，左拐右拐，直到总长度够格。【Legacy `FingerFlowExtension.subPaths()` · New `NewFingerFlowSubPathGenerator.generate()`】
3. **长度预算**：`目标长度 = 你选的秒数 × 15`。秒数越长，弯越多、路越远。【`wholeLengthWithoutStart` / `lengthNeeded`】

视觉上像蛇在爬；工程上像**用圆弧拼出一条可计算的曲线**——既能画出来，也能算出「走到 37% 时手指该在哪」。

这就引出了整个项目最核心的矛盾：

> **人看到的是一条连续的线；代码必须知道线上每一个时刻的坐标。**

Legacy 和 New 解决这个矛盾的方式，气质完全不同。

---

## Legacy：交给 Core Animation 的「黑盒托管」

2023 年的实现，思路比较务实：**让 CA 干活**。

### 状态：到处都在改

`gameState` 散落在 ViewController、Timer 回调、通知里。【`FingerFlowVC.gameState` · `FingerFlowVC+Game.swift`】  
谁都能推一把状态机——像多人同时扶一个醉汉过马路，能走，但没人说得清下一步踩哪块砖。

### 时间：两套钟表

- **业务钟**：`Timer`，每秒跳一次，管倒计时、结束、welldone。【`FingerFlowVC+Game.startTimer(.game)` → `gameTimerAction`】
- **画面钟**：`CAShapeLayer` 的 `strokeEnd` 动画 + 圆点的 `position` 关键帧，`.paced` 沿路径匀速。【见 `FingerFlowGameView.drawCircleList()`】

```swift
// FingerFlowGameView.drawCircleList()
gameLayer.add(CABasicAnimation(keyPath: "strokeEnd"), forKey: "Move")   // 线
circleAnimation.calculationMode = .paced                                  // 点沿路径匀速
guideDot.layer.add(circleAnimation, forKey: "Move")
```

理论上两条时间轴该对齐；实际上 **Timer 走秒、动画走帧**，暂停时还要给 Layer 灌 `speed = 0`【`CALayer.pauseAnimation()` · `FingerFlowExtension.swift`；`FingerFlowGameView.pause()`】——**两套暂停 API，两套心跳**。  
进度条和业务里程碑偶尔「各想各的」，排查起来像查灵异事件。

### 路径：后台算，前台演

准备阶段的 3 秒里，后台线程 `calculatePoints`，把路径点算好。【`FingerFlowGameView.calculatePoints()` → `startPath.subPaths(...)`】  
开跑后 `drawCircleList()` 挂上 Layer，启动双动画：

- **线**：`strokeEnd` 从某个起点拉到 1，画出已走过的轨迹。【`fromValue = startPath.cgPath.length / lengthNeededToRun`】
- **点**：`position` 沿路径爬，时长还和线不一样——这是**刻意保留的手感**（线先「画出来」，点有自己的节奏）。【`dotDuration = duration + startPath.cgPath.length / 15`】

圆点具体在哪？问 `presentationLayer`。【见 `FingerFlowGameView.longPressGuideDot(recognizer:)`】

```swift
guard let guideFrame = guideDot.layer.presentation()?.frame else { ... }
pressState = guideFrame.contains(point) ? .inside : .outside
```

那是 Core Animation 的**黑盒插值**，好看，但 debug 时你只能对着空气猜：「它为什么瞬移了？」

### 命中：问 Layer「你现在在哪」

手指是否跟住圆点？Legacy 看的是 `presentation()?.frame` 矩形区域。【同上 `longPressGuideDot`】  
暂停瞬间、动画边界、插值误差——都可能让判定和眼睛看到的差半拍。

---

## New：自己摆点

### 状态：Reducer 管理

所有变化走 `send(Event) → Reducer → [Effect]`。【`NewFingerFlowViewController.send(_:)` → `NewFingerFlowReducer.send(_:snapshot:)`】  
ViewController 只负责「照单执行」`apply(effects)`——不再到处 `switch gameState`。  
状态图能画、单测能写、QA 能对着表点：从 `preparation` 到 `running` 到 `paused`，每条路有编号。【`NewFingerFlowPhase` · `NewFingerFlowReducer.handlePress`】

### 时间：一根主钟

`NewFingerFlowMasterClock` 用 `CADisplayLink` 维护唯一的 `elapsed`。【`NewFingerFlowMasterClock.swift`】

每一帧【`NewFingerFlowViewController.masterClock(_:didTick:duration:)`】：

1. `applyPlayback(elapsed)` —— 根据进度摆线的 `strokeEnd`、摆圆点的位置。【`NewFingerFlowGameView.applyPlayback(elapsed:duration:)`】
2. `masterClockTick` —— 同一 `elapsed` 判断是否 welldone、是否该结束。【`NewFingerFlowReducer.handleClockTick`】

**业务和画面共用一个时间戳。** 暂停？【`masterClock.suspend()`】冻住 `elapsed`。继续？【`masterClock.resume()`】从同一帧接着走。  
没有「Timer 说你该结束了，但圆点还在半路」这种分裂人格。

### 路径：Seed、公式、裁切

`NewFingerFlowSubPathGenerator` 用 **seed** 掷骰子——同 seed 同路径，便于排查复现 bug。【`generate(..., seed:)` · `SeededRNG` · Debug 结果页 `pathSeed`】

段长不用折线近似，生成时就算 `半径 × 弧度`。【`attemptGenerate`：`radius * angle / 180 * .pi`】  
最后一段如果超预算，不整段重掷，而是**按剩余长度裁角度**——路长更贴 `duration × 15`：

```swift
// NewFingerFlowSubPathGenerator.attemptGenerate()
angle = max(remaining / radius * 180 / .pi, 1)  // 末段裁切
```

路径在开局拼好。【`NewFingerFlowPathBuilder.buildProgressPath` → `NewFingerFlowGameView.rebuildPath(generation:duration:)`】

### 弧长表：只建一次

`NewFingerFlowArcLengthPath` 在构建期沿路径走一遍，存一张 knot 表：  
「总长的 42% 对应坐标 (x, y)」。【`NewFingerFlowArcLengthPath.make(from:pathOrigin:)`】

运行时圆点位置 = **查表**【`point(atFraction:hintIndex:)`】，O(1) 均摊，带 `hintIndex` 顺序访问更快。  
线的 `strokeFraction`、点的 `dotT` 仍保持 Legacy 那套**双线节奏**——手感延续，但规则写在代码里：

```swift
// NewFingerFlowGameView.applyPlayback()
let strokeFraction = strokeStartFraction + (1 - strokeStartFraction) * CGFloat(t)
let dotT = elapsed / (duration + startArcLength / 15)
let point = built.arcLengthPath.point(atFraction: CGFloat(dotT), hintIndex: &arcLengthHintIndex)
```

圆心显示、命中检测、查表坐标**同源**（`lastDotCenter`）。  
判定是 `hypot(触摸点, lastDotCenter) ≤ 55` 的圆【`containsTouchNearGuide`】，不是问 Layer「你猜我在哪」。

### 动效：PropertyAnimator 接力

引导手指的呼吸圈、文案淡入淡出，从无限循环的 `CAKeyframeAnimation` 换成 `UIViewPropertyAnimator` 链。【`NewFingerFlowGuideAnimator` · `NewFingerFlowPromptAnimator`】  
好停、好接、好换文案——暂停恢复时显示 `pausePlace`【`prepareResumeWaiting(elapsed:duration:)`】，不再误用开局的 `place`。

---

## New VS Legacy 更可控


| 你关心的       | Legacy 的感受         | New 的升级                    | 代码出处                                           |
| ---------- | ------------------ | -------------------------- | ---------------------------------------------- |
| **跟手**     | CA 插值，大多时候顺滑       | 同样顺滑，且每帧坐标可查、可 log         | `drawCircleList` / `applyPlayback`             |
| **时长准度**   | Timer 与动画可能漂       | 一个 `elapsed` 说了算           | `gameTimerAction` / `NewFingerFlowMasterClock` |
| **路径长度**   | 末段常「将就」            | 裁切末段，更贴目标长度                | `subPaths` / `attemptGenerate`                 |
| **复现 bug** | 随机路径，难复现           | seed 固定，同一局能再打一遍           | `SeededRNG` · Debug `pathSeed`                 |
| **暂停**     | Timer 停 + Layer 冻结 | 冻 `elapsed`，语义干净           | `pause` + `pauseAnimation` / `suspend`         |
| **命中判定**   | 问 presentation 矩形  | 几何圆，与圆心坐标一致                | `longPressGuideDot` / `containsTouchNearGuide` |
| **改规则**    | 动 CA 配置，心里没底       | 改 `applyPlayback` 几行，所见即所得 | `applyPlayback`                                |
| **维护**     | 状态散落多文件            | Reducer 一张表，Effect 列副作用    | `NewFingerFlowReducer`                         |


玩家未必感知得到这些——**这正是成功的重构**。

---

## 总结

1. **设计**：用随机圆弧拼出一条「刚好够长」的蛇形路，考验手指能不能全程贴住圆点。
2. **Legacy**：路径算好交给 CA，双时钟、黑盒插值、状态四散——能玩，难查。【`FingerFlowGameView.swift` · `FingerFlowVC+Game.swift`】
3. **New**：路径仍随机，但 **seed 可复现、弧长可建表、进度一根钟、摆点自己写**——手感继承，真相归代码。【`NewFingerFlow/` 目录】

---

*文档路径：`YKFingerFlow/DesignStory.md`。技术对照见 `[Optimization.md](Optimization.md)`。*