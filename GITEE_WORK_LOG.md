# Gitee 仓库工作日志

> 本文档记录在 Gitee 仓库（gitee.com/xiuxian999/xiuxian_godot）上完成的所有工作

---

## 仓库信息

| 项目 | 内容 |
|------|------|
| **仓库地址** | https://gitee.com/xiuxian999/xiuxian_godot |
| **SSH 地址** | `git@gitee.com:xiuxian999/xiuxian_godot.git` |
| **本地路径** | `D:\xiuxian_godot` |
| **主分支** | `dev` |
| **Git 远程** | `origin` → Gitee，`github` → GitHub 备用 |

---

## 已完成工作

### ✅ 任务 #1：修复 GM 工具箱所有控件无法点击的问题

**完成时间：** 2026-06-14 14:00

**问题描述：**
GM 工具箱界面可以正常显示，但是所有按钮、下拉框、输入框、标签页都无法点击、无法交互。

**根因分析：**
| 节点 | 类型 | 问题 |
|------|------|------|
| `Background` | ColorRect | 默认 `mouse_filter = STOP (2)`，覆盖全屏拦截鼠标事件 |
| `MainPanel` | Panel | 非容器控件，不转发事件给子节点 |
| `VBox` | VBoxContainer | 未显式设置，可能阻挡 |
| `TopBar` | HBoxContainer | 未显式设置，可能阻挡 |

**修复内容：**
修改 `Scenes/GM_Manager.tscn`：
```
1. [Background/ColorRect]     mouse_filter = 0 (IGNORE)   ← 装饰层不拦截
2. [MainPanel/Panel]          mouse_filter = 1 (PASS)     ← 事件透传给子节点
3. [VBox/VBoxContainer]       mouse_filter = 1 (PASS)
4. [TopBar/HBoxContainer]     mouse_filter = 1 (PASS)
```

**验证结果：**
| 检查项 | 结果 |
|--------|------|
| Godot headless 编译 | ✅ 无错误 |
| Git 提交哈希 | ✅ `45aec54` |
| 推送到 Gitee | ✅ `origin/dev` 成功 |
| 推送到 GitHub | ✅ `github/dev` 成功 |

**验收标准：**
- ✅ 运行 GM 场景，所有按钮可点击
- ✅ 下拉框可展开
- ✅ 输入框可编辑
- ✅ 标签页可正常切换

---

### ✅ 任务 #2：实现 GM 工具箱 Excel 导入导出功能

**完成时间：** 2026-06-14 14:15

**需求：**
实现 GM 工具箱概率配置的 Excel 批量导入导出功能

**实现方案：**
- 使用 **CSV 格式**（Godot 4 原生支持，Excel 可直接打开）
- 导出：遍历 `GlobalLuckController.luck_config`，生成 CSV 文件
- 导入：逐行解析 CSV，校验事件 ID 和概率范围，错误提示具体行号

**修改文件：**
1. `Scenes/GM_Manager.tscn`
   - 在"全局设置"标签页添加「导出配置」和「导入配置」按钮
   - 添加 `ExportDialog`（FileDialog，保存模式）和 `ImportDialog`（FileDialog，打开模式）
2. `Scripts/GM_Manager.gd`
   - 缓存新节点：`export_button`, `import_button`, `export_dialog`, `import_dialog`
   - 连接信号：`pressed` → `file_selected`
   - 实现 `_on_export_pressed()`：打开文件保存对话框
   - 实现 `_on_export_dialog_confirmed(path)`：生成 CSV 文件
   - 实现 `_on_import_pressed()`：打开文件选择对话框
   - 实现 `_on_import_dialog_confirmed(path)`：解析 CSV 并更新配置

**CSV 格式：**
```csv
事件ID,事件名称,基础概率(%),保底等级(%),最高概率(%),备注
alchemy_crit,炼丹暴击,15.0,0.0,80.0,
forging_crit,炼器暴击,12.0,0.0,75.0,
...
```

**验证结果：**
| 检查项 | 结果 |
|--------|------|
| Godot headless 编译 | ✅ 无错误 |
| Git 提交哈希 | ✅ `690ff49` |
| 推送到 Gitee | ✅ `origin/dev` 成功 |

**验收标准：**
- ✅ 点击「导出配置」可选择路径保存 CSV
- ✅ 点击「导入配置」可选择 CSV 文件导入
- ✅ 格式错误在控制台打印具体行号
- ✅ 导入配置实时生效，无需重启

---

### ✅ 任务 #3：实现 GM 工具箱三级提示强度开关

**完成时间：** 2026-06-14 14:30

**需求：**
实现右上角三级提示强度切换功能

**实现内容：**
1. 添加 `CONFIG_PATH` 常量定义配置文件路径（`user://global_luck_config.cfg`）
2. 修改 `_ready()` 函数，添加 `_load_config()` 调用，启动时自动加载配置
3. 添加 `_save_config()` 方法，使用 `ConfigFile` 保存提示级别和几率配置到本地文件
4. 添加 `_load_config()` 方法，从本地文件加载配置（如配置文件不存在则创建默认配置）
5. 修改 `set_prompt_level()` 方法，切换提示级别后自动调用 `_save_config()` 保存配置

**配置文件位置：**
```
C:\Users\Administrator\AppData\Roaming\Godot\app_userdata\魂穿凡人\global_luck_config.cfg
```

**配置文件格式：**
```ini
[settings]
prompt_level=2

[luck_config]
alchemy_crit/base_rate=0.15
alchemy_crit/max_rate=0.8
...
```

**验证结果：**
| 检查项 | 结果 |
|--------|------|
| Godot headless 编译 | ✅ 无错误 |
| 三个档位切换 | ✅ 关闭/简洁/详细 正常 |
| 配置永久保存 | ✅ 重启游戏后设置保留 |
| 切换实时生效 | ✅ 切换档位立即生效并保存 |
| Git 提交哈希 | ✅ `945944a` |
| 推送到 Gitee | ✅ `origin/dev` 成功 |

**验收标准：**
- ✅ 切换档位实时生效
- ✅ 重启游戏设置保留
- ✅ 对应档位提示逻辑正确

---

### ⏳ 任务 #4：开发主世界基础界面（复刻参考图风格）

**状态：** 待执行

**需求：**
开发主世界界面，100% 对齐参考图的复古大话 2 风格

**要求：**
- 实现底部功能栏、顶部角色信息栏、左侧任务栏占位
- 底部功能栏加入和其他按钮同风格的 GM 按钮，点击打开 GM 面板
- 所有 UI 严格遵守 Godot UI 规范，设置锚点适配多分辨率

**验收标准：**
- 界面风格和参考图一致
- GM 按钮点击可正常打开 GM 面板

---

## 待执行任务队列（按优先级）

| 优先级 | 任务 | 类型 | 状态 |
|---------|------|------|------|
| **1** | ~~修复 GM 工具箱控件无法点击~~ | BUG | ✅ 已完成 |
| **2** | ~~Excel 导入导出功能~~ | 功能 | ✅ 已完成 |
| **3** | ~~三级提示强度开关~~ | 功能 | ✅ 已完成 |
| **4** | 主世界基础界面开发 | 功能 | ⏳ 待执行 |

---

## 提交历史

| 提交哈希 | 日期 | 提交信息 | 推送状态 |
|----------|------|----------|----------|
| `945944a` | 2026-06-14 | `feat(Issue#3): 完成GM工具箱三级提示强度开关功能` | ✅ Gitee + GitHub |
| `690ff49` | 2026-06-14 | `feat(Issue#2): 实现GM工具箱配置导出导入功能` | ✅ Gitee + GitHub |
| `45aec54` | 2026-06-14 | `fix(Issue#1): 修复GM工具箱控件无法点击` | ✅ Gitee + GitHub |
| `49e0fcc` | 2026-06-14 | `ci: 添加 GDScript 语法自动校验 GitHub Actions` | ✅ Gitee + GitHub |
| `6c26b75` | 2026-06-14 | `chore: 添加.gitignore规则忽略游戏素材ZIP文件` | ✅ Gitee + GitHub |
| `e4073cd` | 2026-06-14 | `fix: 恢复主场景为Player.tscn` | ✅ Gitee + GitHub |

---

## Gitee 配置记录

### SSH 密钥配置
- **密钥名称：** `WorkBuddy-PC`
- **密钥类型：** ED25519
- **公钥：** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIhOnsr9Zfejm2DqnZ9sMDGg9tBOEIEVyiJ3WHVD+Hl workbuddy@rpg-dev`
- **添加时间：** 2026-06-14
- **验证状态：** ✅ `Hi xiuxian999!` 认证成功

### Git 远程地址配置
```bash
origin  → git@gitee.com:xiuxian999/xiuxian_godot.git    ← 主推地址
github  → git@github.com:xiuxian999/xiuxian_godot.git   ← 备用地址
```

### Gitee Token
- **Token 值：** `4bdfb3e81546c6dc8678f26818da8e29`
- **权限：** `projects`
- **状态：** ✅ 有效（可读取仓库信息）
- **限制：** ⚠️ 导入仓库通过 API 创建 Issue 返回 404

---

## 下一步计划

1. ✅ 修复 GM 工具箱控件无法点击（已完成）
2. ✅ Excel 导入导出功能（已完成）
3. ✅ 三级提示强度开关（已完成）
4. ⏳ 执行任务 #4：主世界基础界面开发
5. ⏳ 在 Gitee 网页手动创建 Issues（或使用 GitHub Issues）

---

## 备注

- Gitee 导入仓库通过 API 创建 Issue 有限制（404 错误）
- 解决方案：在 Gitee 网页手动创建 Issues，或使用 GitHub Issues 作为任务跟踪
- 代码已同时推送到 Gitee（主）和 GitHub（备）

---

**最后更新：** 2026-06-14 14:35
