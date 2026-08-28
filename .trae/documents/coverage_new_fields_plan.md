# Coverage 新增字段实现计划

## 一、需求来源

飞书文档「coverage新增字段」(<https://my.feishu.cn/docx/MtnedkVIaoAOmvxa8CzceI6Ontf>) 中嵌入了两张电子表格，分别定义了 `bs_net_ltecoverage_base_q` 和 `bs_net_nrcoverage_base_q` 需要新增的字段及计算逻辑。

## 二、新增字段清单

### 2.1 LTE 表新增字段（12个）

| #  | 字段名                    | 中文名             | 类型     | 计算逻辑                                   |
| -- | ---------------------- | --------------- | ------ | -------------------------------------- |
| 1  | totalta                | TA总值            | bigint | sum(C027)                              |
| 2  | tacount                | TA有效的MR总数       | bigint | C027不为空的样本数                            |
| 3  | beforetherotysinrcount | 下行Sinr有效的MR总数   | bigint | C125不为空的样本数                            |
| 4  | totalbeforetherotysinr | 下行Sinr总值        | double | sum(C125)                              |
| 5  | totalcqi0              | cqi0总值          | bigint | sum(C123)                              |
| 6  | cqi0count              | cqi0有效的MR总数     | bigint | C123不为空的样本数                            |
| 7  | totalulmcs             | 上行MCS总值         | bigint | sum(case when c022 <> 0 then c022 end) |
| 8  | ulmcscount             | 上行MCS有效的MR总数    | bigint | c022<>0的样本数                            |
| 9  | totaldlmcs             | 下行MCS总值         | bigint | sum(case when c023 <> 0 then c023 end) |
| 10 | dlmcscount             | 下行MCS有效的MR总数    | bigint | c023<>0的样本数                            |
| 11 | allerabulpdcptputcount | 上行pdcp流量有效的MR总数 | bigint | C137不为空的样本数                            |
| 12 | allerabdlpdcptputcount | 下行pdcp流量有效的MR总数 | bigint | C138不为空的样本数                            |

### 2.2 NR 表新增字段（8个）

| # | 字段名                      | 中文名                       | 类型     | 计算逻辑                       |
| - | ------------------------ | ------------------------- | ------ | -------------------------- |
| 1 | totalta                  | TA总值                      | bigint | sum(TA)                    |
| 2 | tacount                  | TA有效的MR总数                 | bigint | TA不为空的样本数                  |
| 3 | totalulsinr              | 上行Sinr总值                  | double | sum(ulsinr)                |
| 4 | ulsinrcount              | 上行Sinr有效的MR总数             | bigint | ulsinr不为空的样本数              |
| 5 | totalcqi0                | cqi0总值                    | bigint | sum(cqi0)                  |
| 6 | cqi0count                | cqi0有效的MR总数               | bigint | cqi0不为空的样本数                |
| 7 | dlpdcpsendvolumesumcount | 下行PDCP成功接收的RLC层数据量有效的MR数  | bigint | dlpdcpsendvolumesum不为空的样本数 |
| 8 | ulpdcprcvvolumesumcount  | 上行PDCP层成功递交给RLC层数据量有效的MR数 | bigint | ulpdcprcvvolumesum不为空的样本数  |

## 三、现有代码分析

### 3.1 LTE SQL 数据流

文件：`/workspace/zxwinmo-b-net-ievaluate/bs_net_ltecoverage_base_q.sql`

数据流经三层 CTE：

1. **s1 子查询**（第271-282行）：从 `$l_t054_ex$` 读取原始字段，当前 SELECT 列表中：

   * `c027`（TA）✅ 已选取

   * `c137`（allerabulpdcptput）✅ 已选取

   * `c138`（allerabdlpdcptput）✅ 已选取

   * `c022`（上行MCS）❌ 未选取

   * `c023`（下行MCS）❌ 未选取

   * `c123`（cqi0）❌ 未选取

   * `c125`（下行Sinr）❌ 未选取

2. **temp\_mrdataAll 外层 SELECT**（第207-268行）：将 s1 字段映射为有意义的别名：

   * `c027 as ta` ✅

   * `c137 as allerabulpdcptput` ✅

   * `c138 as allerabdlpdcptput` ✅

   * 需要新增：`c022 as ulmcs`、`c023 as dlmcs`、`c123 as cqi0`、`c125 as beforetherotysinr`

3. **temp\_mrdata\_hdoaCorrection**（第299-358行）：透传 CTE，包含内层 SELECT（第347-356行）和外层 SELECT（第300-345行），两层都需要补充新字段。

4. **最终聚合 SELECT**（第359-451行）：按维度 GROUP BY 后输出指标，需要在末尾追加 12 个聚合表达式。

### 3.2 NR SQL 数据流

文件：`/workspace/zxwinmo-b-net-ievaluate/bs_net_nrcoverage_base_q.sql`

1. **s1 子查询**（第372-408行）：从 `$nr_t054_ex$` 读取原始字段：

   * `ta` ✅ 已选取

   * `dlpdcpsendvolumesum` ✅ 已选取

   * `ulpdcprcvvolumesum` ✅ 已选取

   * `ulsinr` ❌ 未选取

   * `cqi0` ❌ 未选取

2. **temp\_mrdataAll 外层 SELECT**（第314-369行）：需要新增 `ulsinr`、`cqi0` 的透传。

3. **temp\_mrdata\_hdoaCorrection**（第426-477行）：内外两层 SELECT 都需要补充 `ulsinr`、`cqi0`。

4. **最终聚合 SELECT**（第478-544行）：需要在末尾追加 8 个聚合表达式。

## 四、修改步骤

### 4.1 修改 LTE SQL

#### 步骤 1：s1 子查询增加源字段（第272行附近）

在 s1 的 SELECT 列中添加 `c022, c023, c123, c125`。

#### 步骤 2：temp\_mrdataAll 外层 SELECT 增加字段映射（第232行 `c027 as ta` 附近）

添加：

```sql
c022 as ulmcs,
c023 as dlmcs,
c123 as cqi0,
c125 as beforetherotysinr,
```

#### 步骤 3：temp\_mrdata\_hdoaCorrection 内层 SELECT 增加字段（第350行附近）

在内层 SELECT 列表中添加 `ulmcs, dlmcs, cqi0, beforetherotysinr`。

#### 步骤 4：temp\_mrdata\_hdoaCorrection 外层 SELECT 增加字段（第325行附近）

在外层 SELECT 列表中添加 `ulmcs, dlmcs, cqi0, beforetherotysinr`。

#### 步骤 5：最终聚合 SELECT 追加 12 个字段（第449行 `azimuthalign_mrcount` 之后）

```sql
,sum(ta) as totalta
,count(ta) as tacount
,count(beforetherotysinr) as beforetherotysinrcount
,sum(beforetherotysinr) as totalbeforetherotysinr
,sum(cqi0) as totalcqi0
,count(cqi0) as cqi0count
,sum(case when ulmcs <> 0 then ulmcs end) as totalulmcs
,count(case when ulmcs <> 0 then 1 end) as ulmcscount
,sum(case when dlmcs <> 0 then dlmcs end) as totaldlmcs
,count(case when dlmcs <> 0 then 1 end) as dlmcscount
,count(allerabulpdcptput) as allerabulpdcptputcount
,count(allerabdlpdcptput) as allerabdlpdcptputcount
```

### 4.2 修改 NR SQL

#### 步骤 1：s1 子查询增加源字段（第400行 `ta, hdoa` 附近）

在 s1 的 SELECT 列中添加 `ulsinr, cqi0`。

#### 步骤 2：temp\_mrdataAll 外层 SELECT 增加字段（第351行 `ta` 附近）

添加 `ulsinr, cqi0` 的透传。

#### 步骤 3：temp\_mrdata\_hdoaCorrection 内层 SELECT 增加字段（第471行附近）

在内层 SELECT 列表中添加 `ulsinr, cqi0`。

#### 步骤 4：temp\_mrdata\_hdoaCorrection 外层 SELECT 增加字段（第465行附近）

在外层 SELECT 列表中添加 `ulsinr, cqi0`。

#### 步骤 5：最终聚合 SELECT 追加 8 个字段（第542行 `azimuthalign_mrcount` 之后）

```sql
,sum(ta) as totalta
,count(ta) as tacount
,sum(ulsinr) as totalulsinr
,count(ulsinr) as ulsinrcount
,sum(cqi0) as totalcqi0
,count(cqi0) as cqi0count
,count(dlpdcpsendvolumesum) as dlpdcpsendvolumesumcount
,count(ulpdcprcvvolumesum) as ulpdcprcvvolumesumcount
```

## 五、注意事项

1. **GROUP BY 无需修改**：新增字段均为聚合指标（sum/count），不涉及维度变更。
2. **字段顺序**：新增字段统一追加在最终 SELECT 的末尾（`azimuthalign_mrcount` 之后、`from` 之前），不破坏现有字段顺序。
3. **源表字段依赖**：LTE 的 `$l_t054_ex$` 需包含 c022、c023、c123、c125 列；NR 的 `$nr_t054_ex$` 需包含 ulsinr、cqi0 列。按文档要求假定这些字段在源表中存在。
4. **count 语义**：`count(field)` 自动排除 NULL 值，符合"不为空的样本数"要求。
5. **MCS 条件计数**：`count(case when ulmcs <> 0 then 1 end)` 在条件不满足（含 NULL）时返回 NULL，被 count 排除，符合"c022<>0的样本数"要求。
6. **数据类型**：`totalbeforetherotysinr` 和 `totalulsinr` 为 double 类型，其余新增字段为 bigint 类型，Spark SQL 的 sum/count 会自动推断。
7. **CTE 透传完整性**：temp\_mrdata\_hdoaCorrection 的内外两层 SELECT 必须同步添加新字段，否则外层无法引用。

## 六、风险评估

* **低风险**：所有修改均为新增字段，不修改或删除现有字段和逻辑。

* **潜在风险**：如果源表 `$l_t054_ex$` 或 `$nr_t054_ex$` 中不存在文档要求的列，SQL 执行时会报错。需在实际运行环境中确认源表 schema。

