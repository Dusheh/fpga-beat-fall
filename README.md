# Rhythm Master · 基于 FPGA 的数字音乐播放器

> Cyclone IV E (EP4CE6F17C8) · Verilog HDL · Quartus Prime 18.1 Lite
> 课程实践周项目 · 🚧 仍在开发中

用一块 FPGA 开发板 + 一个无源蜂鸣器做出来的**纯硬件音乐播放器**：没有 CPU、没有软件、没有 PWM 外设库，
从分频计数到乐谱查表全部由 Verilog 时序逻辑完成，按下按键就能把一首完整的曲子放出来。

---

## 1. 项目简介

整个播放链路只用三层逻辑：

```
乐谱表(ROM) ──► 周期查表 / 节拍计时 ──► PWM 方波发生器 ──► 蜂鸣器
```

- **音高**：每个音符对应一个"时钟周期数"（50 MHz 晶振下 1 个周期 = 20 ns），计数器数满即翻转电平，
  得到精确频率的方波；
- **节拍**：以 BPM 为基准换算出 1 拍的时钟数，再用音符时值（1/2/4/8/16 分音符）分频，
  决定当前音符保持多久；
- **发声**：50% 占空比方波驱动无源蜂鸣器，方波的谐波足够丰富，听感上就是那个音。

这样做的好处是完全可综合、可移植：换一块板子只要改引脚约束，换一首歌只要改乐谱表。

## 2. 硬件平台

| 项目 | 说明 |
| --- | --- |
| 开发板 | AWC_C4 + DVK 底板 |
| 主芯片 | Altera/Intel Cyclone IV E **EP4CE6F17C8**（F256 封装，6272 LE） |
| 时钟 | 50 MHz 板载有源晶振 |
| 发声 | 无源蜂鸣器，单管脚 PWM 驱动 |
| 输入 | 独立按键 ×5（复位/重播 + 4 个功能键） |
| 预留输出 | WS2812 8×8 RGB 点阵、数码管、进度 LED（渲染模块已写，尚未接入主链路） |

> 板上按键为**低有效**接法（按下为 0，松开为 1），这也是 `replay` / `enable` 在逻辑里当 `rst_n`
> 使用的原因。

## 3. 当前进度

| 模块 | 功能 | 状态 |
| --- | --- | --- |
| `main` | 顶层，实例化主控并把外设接出去 | ✅ |
| `gameController` | 主状态机：菜单→选曲→演奏→结算，统一调度下面所有外设 | ✅ 已实现 |
| `songData` / `songDataQT` / `songDataGetter` | 乐谱 ROM、节拍、音符取数 | ✅ |
| `beep` | PWM 方波发声 | ✅ |
| `rgbRenderer` | WS2812 8×8 点阵驱动（双缓冲 + 时序生成） | ✅ 已接入 |
| `digitalRenderer` + `digital/sel_ctrl.v` + `digital/show.v` | 数码管动态扫描与显示 | ✅ 已接入 |
| `progressLED` | 4 个进度灯 | ✅ |
| `tonePlayer` | PWM 初版实现（已被 `beep` 取代） | 🗄 保留作参考 |
| `database` | 曲库扩展（预留） | ⬜ 空 |
| `sim/` | 仿真测试（蜂鸣器 / 点阵） | ✅ |

**现在能做什么：** 上电进菜单，按键选曲开始演奏——蜂鸣器放旋律、8×8 点阵显示下落音符、
数码管显示分数、进度灯点亮，按到音符得分，一首结束进结算再回菜单。

## 4. 系统结构

```
                  ┌──────────────────────────────────────────┐
    50MHz clk ───►│                                          │
                  │  songData                                │
      replay ────►│   ├─ tones[0..404]  (音符周期表)          │──► tone[25:0] ──┐
                  │   ├─ ttime[0..404]  (音符时值)            │                  │
      enable ────►│   └─ idx 指针 / cnt_t 节拍计数            │                  ▼
                  │                                          │              ┌────────┐
                  │                                          │              │  beep  │──► beepPwm ──► 🔈
                  └──────────────────────────────────────────┘              │  PWM   │
                                                                            └────────┘
```

`main.v` 只做连线和例化：把 `gameController` 和所有外设接起来，逻辑全在 `gameController` 里。

## 5. 音高与节拍是怎么算的

### 5.1 音高（周期表）

50 MHz 时钟下，标准音 A4 = 440 Hz，一个周期需要 `50_000_000 / 440 ≈ 113636` 个时钟。
于是每个音名都被写成"半周期基准值 × 50"的形式，例如：

```verilog
localparam LDO = 3816 * 50;  // 低音 DO  (261.6 Hz → 191,131 clk)
localparam DO  = 1912 * 50;  // 中音 DO  (523.3 Hz)
localparam HDO = 955  * 50;  // 高音 DO  (1046.5 Hz)
```

同一八度内相邻音名的比例都是 2 的 1/12 次方，所以高八度正好是低八度的一半。

### 5.2 节拍

```verilog
localparam Nowbpm = 8'd64;                    // 每分钟 64 拍
localparam bps    = 50_000_000 / Nowbpm * 60; // 每拍时钟数
```

每个音符的时值字段 `ttime` 用 1/2/4/8/16 表示音符长度，再换算成实际保持的时钟数：

| `ttime` | 含义 | 持续时间 |
| --- | --- | --- |
| 1 | 全音符 | `4 × bps` |
| 2 | 二分音符 | `2 × bps` |
| 4 | 四分音符 | `1 × bps` |
| 8 | 八分音符 | `bps / 2` |
| 16 | 十六分音符 | `bps / 4` |

指针 `idx` 每到时间就把 `tones[idx]` 送到 PWM 模块，走完 404 个音符后 `finish` 拉高、输出静音。

### 5.3 PWM

```verilog
assign pwm = (cnt <= FREQ_T * 50 / 100) ? 1'b1 : 1'b0;  // 50% 占空比
```

计数器在 `0 ~ FREQ_T-1` 之间循环，前半周期输出高、后半周期输出低，得到对应频率的方波。

## 6. 目录结构

```
.
├── README.md
├── src/                     # Quartus 工程目录（RTL 与工程文件同目录，路径开箱即用）
│   ├── rhythmMaster.qpf     # Quartus 工程文件
│   ├── main.qsf             # 引脚约束 / 文件列表
│   ├── main.sdc             # 时序约束（50 MHz）
│   ├── main.v               # 顶层
│   ├── gameController.v     # 主状态机（菜单/选曲/演奏/结算）
│   ├── songData.v           # 乐谱 ROM + 节拍
│   ├── songDataQT.v         # 乐谱数据
│   ├── songDataGetter.v     # 音符取数
│   ├── beep.v               # PWM 方波发生器
│   ├── digital/             # 数码管：位选 + 显示
│   ├── tonePlayer.v         # PWM 初版（参考）
│   ├── rgbRenderer.v        # WS2812 点阵驱动（未接入）
│   ├── digitalRenderer.v    # 数码管渲染
│   └── database.v           # 曲库（待实现）
├── bitstream/
│   └── rhythmMaster.sof     # 可直接烧录的配置文件
├── sim/                     # 仿真验证（Icarus Verilog）
│   ├── tb_beep.v            # 蜂鸣器驱动测试：换音毛刺 / 占空比 / 频率
│   └── Makefile
└── docs/
    └── design-notes.md      # 设计笔记：状态机规划、待办、调试记录
```

## 7. 编译与烧录

**环境**：Quartus Prime 18.1 Lite（本工程由 18.1.0 Build 625 生成；Cyclone IV E 需使用带该器件库的版本）。

```bash
# 打开工程
quartus src/rhythmMaster.qpf

# 或者命令行全流程
cd src
quartus_sh --flow compile main
```

烧录：`Tools → Programmer → 选择 bitstream/rhythmMaster.sof → Start`
（也可以先用 `Programmer` 直接把 `sof` 下到 SRAM 里试听，掉电即失效）。

### 仿真验证（可选）

需要 Icarus Verilog：`brew install icarus-verilog`

```bash
cd sim
make beep      # 蜂鸣器：统计每段电平宽度，< 1us 的电平段标成 RUNT（换音毛刺）
make rgb       # 点阵：写入 8x8 测试图案，把输出比特流解码回来逐像素比对
```

两个测试激励都是按"现象量化"写的：不告诉你在哪出错，只把异常的数字打出来——
这正是定位问题的第一步。

## 8. 引脚分配

| 信号 | 引脚 | 说明 |
| --- | --- | --- |
| `clk` | PIN_E1 | 50 MHz 晶振 |
| `beepPwm` | PIN_J1 | 蜂鸣器 PWM 输出 |
| `replay` | PIN_F8 | KEY1，低有效：按下即从头重播 |
| `enable` | PIN_N11 | 播放使能，高有效（空闲须为 1） |
| `buttons[0]` | PIN_E15 | 功能键 1 |
| `buttons[1]` | PIN_E16 | 功能键 2 |
| `buttons[2]` | PIN_M15 | 功能键 3 |
| `buttons[3]` | PIN_M16 | 功能键 4 |
| `rgb_martix` | PIN_K6 | WS2812 点阵数据 |
| `digitalLED[7:0]` | A5 B8 A7 B6 B5 A6 A8 B7 | 数码管段码 |
| `digitalSelect[5:0]` | B1 A2 B3 A3 B4 A4 | 数码管位选 |
| `progressLED[3:0]` | D16 F15 F16 G15 | 进度指示 |

IO 标准统一为 `3.3-V LVCMOS`。

## 9. 已知问题

这一版重写了主控（`gameController` 接管全部外设），早期的问题清单已经不能照用了。
具体条目都在 [Issues](https://github.com/Dusheh/fpga-rhythm-master/issues) 里跟踪，
验证过就关掉；还缺的功能见下面路线图。

## 10. 路线图

- [x] 蜂鸣器按乐谱播放旋律
- [x] 按键重播
- [ ] 修掉已知问题（见 Issues 列表）
- [ ] 加音符包络（淡入淡出），让起音更柔
- [ ] 支持多首曲目 + 按键切歌
- [x] 接入 WS2812 8×8 点阵：下落音符可视化
- [ ] 按键判定与计分（节奏游戏玩法）
- [x] 数码管显示分数 / 进度 LED
- [x] 完整状态机：菜单 → 选曲 → 演奏 → 结算（`gameController.v`）

## 11. 许可

MIT License，见 [LICENSE](LICENSE)。

---

_课程实践周作品，还在写。欢迎提 issue 一起改。_
