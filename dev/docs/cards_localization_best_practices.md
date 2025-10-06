# cards.cdb 本地化经验总结

以下记录一次完成 `cards.cdb` 中文 → 英文本地化的关键实践，便于未来重复使用。

## 准备阶段
- **锁定权威术语表**：先阅读 `dev/docs/guide/gcg_Glossary.md` 与 `locales/en-US/strings.conf`，形成部署/补给/影响力等术语映射，保证翻译一致。
- **明确数据库结构**：`texts` 表共有 19 列（`id`、`name`、`desc`、`str1`…`str16`）。翻译时必须保持字段数量与顺序一致，尤其是空提示位要使用空字符串占位。
- **确认导入范围**：仅导出 / 导入 `texts`，避免误改 `datas` 数值字段。

## 翻译与导入
- **保持 SQL 结构**：翻译输出为 `INSERT OR REPLACE INTO texts VALUES(...)`，行内字段仍使用单引号；需要换行时直接写入真实的换行符而非 `\n`。
- **统一术语写法**：常见替换示例：
  - “部署时” → “When deployed,”
  - “在部署的回合就可以攻击” → “Can attack the turn it is deployed.”
  - “保护友军单位” → “Protect allied units.”
  - “免疫1次伤害” → “Immune to 1 instance of damage.”
  - “送往游戏外” → “Exile”
  - “消耗 X 点补给” → “Spend X Supply”
- **空字段填充**：若中文 `str` 列为空，也必须在英文 SQL 中填入 `''`；反之亦然，防止提示错位。

## 质量校验
- **导入前校验字段数量**：利用脚本统计 `INSERT` 的逗号/括号，确保每条语句 19 个值。
- **导入后比对**：编写脚本对比 `zh-CN` 与 `en-US` 的每列是否都存在值，快速定位缺失或多余的提示文本。
- **查找术语异动**：通过 `rg` 或 SQL 抽样，确认关键术语（Deploy、Supply、Influence、Temporary 等）符合术语表。
- **换行检查**：导入后执行 `REPLACE(column, '\\n', char(10))` 或聚合查询确认库内不再遗留 `\n` 字面值。

## 回滚与备份
- 导入前保留旧库（如 `cards.cdb.bak`），便于出现错误时快速回退。

## 建议的自动化步骤
1. 由中文导出 `INSERT` 脚本。
2. 翻译并生成 `english_texts_fixed.sql`，确保 19 列齐全。
3. 用 `sqlite3 cards.cdb < english_texts_fixed.sql` 导入，同时提前备份。
4. 跑差异脚本校验、抽查术语与换行展示。

遵循以上流程，可在保持术语统一的前提下，快速完成 `cards.cdb` 多语言文本替换。***
