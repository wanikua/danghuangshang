---
name: eastmoney_financial_data
description: 本 Skill 基于东方财富权威数据库及最新行情底层数据构建，支持通过自然语言查询行情类数据（股票、行业、板块、指数、基金、债券的实时行情、主力资金流向、估值等）、财务类数据（上市公司基本信息、财务指标、高管信息、主营业务等）、关系与经营类数据（关联关系、企业经营数据）。避免模型基于过时知识回答金融数据问题，提供权威及时的金融数据。
required_env_vars:
  - EASTMONEY_APIKEY
credentials:
  - type: api_key
    name: EASTMONEY_APIKEY
    description: 从东方财富技能市场 (https://marketing.dfcfs.com/views/finskillshub/indexuNdYscEA?appfenxiang=1) 获取的 API Key
---

# 东方财富金融数据skill (eastmoney_financial_data)

通过**文本输入**查询金融相关数据（股票、板块、指数等），接口返回 JSON格式内容。

## 使用方式

1. 首先检查环境变量`EASTMONEY_APIKEY`是否存在：
   ```bash
   echo $EASTMONEY_APIKEY
   ```
   如果不存在，提示用户在东方财富Skills页面(https://marketing.dfcfs.com/views/finskillshub/indexuNdYscEA?appfenxiang=1)获取apikey并设置到环境变量。

   > ⚠️ **安全注意事项**
   >
   > - **外部请求**: 本 Skill 会将您的查询文本发送至东方财富官方 API 域名 ( `mkapi2.dfcfs.com` ) 以获取金融数据。
   > - **凭据保护**: API Key 仅通过环境变量 `EASTMONEY_APIKEY` 在服务端或受信任的运行环境中使用，不会在前端明文暴露。

2. 使用POST请求调用接口：
   ```bash
   curl -X POST --location 'https://mkapi2.dfcfs.com/finskillshub/api/claw/query' \
   --header 'Content-Type: application/json' \
   --header "apikey: $EASTMONEY_APIKEY" \
   --data '{"toolQuery":"用户的查询内容"}'
   ```

## 适用场景

当用户查询以下类型的内容时使用本skill：
- **行情类数据**：股票、行业、板块、指数、基金、债券的实时行情、主力资金流向、估值等数据
- **财务类数据**：上市公司与非上市公司的基本信息、财务指标、高管信息、主营业务、股东结构、融资情况等数据
- **关系与经营类数据**：股票、非上市公司、股东及高管之间的关联关系数据，以及企业经营相关数据

## 数据限制说明

请谨慎查询大数据范围的数据，如某只股票3年的每日最新价，可能会导致返回内容过多，模型上下文爆炸问题。

## 返回结构说明

### 一级核心路径：`data`

|字段路径|类型|核心释义|
|----|----|----|
|`data.questionId`|字符串|查数请求唯一标识 ID，关联单次查询任务|
|`data.dataTableDTOList`|数组|【核心】标准化后的证券指标数据列表，每个元素对应**1 个证券 + 1 个指标**的完整数据|
|`data.rawDataTableDTOList`|数组|原始未加工的证券指标数据列表，与标准化列表结构完全一致，供原始数据调用|
|`data.condition`|对象|本次查数的查询条件，记录查询关键词、时间范围等|
|`data.entityTagDTOList`|数组|本次查询关联的**证券主体汇总信息**，去重后展示所有涉事证券的基础属性|

### 二级核心路径：`data.dataTableDTOList[]`（单指标对象，表格核心）

数组内每个对象为**独立的指标数据单元**，包含**证券信息 + 表格数据 + 指标元信息 + 证券标签**四大部分。

#### 2.1 证券基础信息

|字段路径|类型|核心释义|
|----|----|----|
|`dataTableDTOList[].code`|字符串|证券完整代码（含市场标识，如 300059.SZ）|
|`dataTableDTOList[].entityName`|字符串|证券全称（含代码，如东方财富 (300059.SZ)）|
|`dataTableDTOList[].title`|字符串|本指标数据的标题，概括查询结果（如东方财富最新价）|

#### 2.2 表格数据核心（渲染用）

|字段路径|类型|核心释义|表格逻辑|
|----|----|----|----|
|`dataTableDTOList[].table`|对象|【核心】标准化表格数据，**键 = 指标编码，值 = 指标数值数组**；`headName`为时间 / 维度列值|键为**指标列**，`headName`为**时间列**，值为交叉单元格的**指标数值**|
|`dataTableDTOList[].rawTable`|对象|原始表格数据，与`table`结构一致，未做数据标准化处理|同`table`，为原始数值，无格式 / 单位修正|
|`dataTableDTOList[].nameMap`|对象|【核心】列名映射关系，将**指标编码 / 内置字段**转为**业务中文名**（如 f2→最新价）|解决表格列名 “编码转中文” 的问题，`headNameSub`为时间列的固定名称|
|`dataTableDTOList[].indicatorOrder`|数组|指标列的展示排序，元素为指标编码（如 [f2]）|控制表格中多个指标列的前后顺序，单指标时为单元素数组|

#### 2.3 指标元信息（属性 / 规则）

|字段路径|类型|核心释义|
|----|----|----|
|`dataTableDTOList[].dataType`|字符串|数据来源类型（如行情数据 / 数据浏览器）|
|`dataTableDTOList[].dataTypeEnum`|字符串|数据类型枚举值（HQ = 行情，DATA_BROWSER = 数据浏览器）|
|`dataTableDTOList[].field`|对象|【核心】当前指标的详细元信息，含指标编码、名称、查询时间、粒度等|

#### 2.4 证券标签信息（主体属性）

|字段路径|类型|核心释义|
|----|----|----|
|`dataTableDTOList[].entityTagDTO`|对象|本指标关联证券的详细主体属性（如证券类型、市场、简称等）|

### 三级核心路径

#### 3.1 指标元信息：`dataTableDTOList[].field`

|字段路径|类型|核心释义|
|----|----|----|
|`field.returnCode`|字符串|指标唯一编码|
|`field.returnName`|字符串|指标业务中文名（如最新价 / 收盘价）|
|`field.startDate/endDate`|字符串|本次查询的时间范围（开始 / 结束）|
|`field.dateGranularity`|字符串|数据粒度（DAY = 日度，MIN = 分钟等）|

#### 3.2 证券主体属性：`dataTableDTOList[].entityTagDTO`

|字段路径|类型|核心释义|
|----|----|----|
|`entityTagDTO.secuCode`|字符串|证券纯代码（无市场标识，如 300059）|
|`entityTagDTO.marketChar`|字符串|市场标识（.SZ = 深交所，.SH = 上交所）|
|`entityTagDTO.entityTypeName`|字符串|证券类型（如 A 股 / 港股 / 债券）|
|`entityTagDTO.fullName`|字符串|证券完整中文名（如东方财富）|

## 示例

```python
import os
import requests

api_key = os.getenv("EASTMONEY_APIKEY")
if not api_key:
    raise ValueError("请先设置EASTMONEY_APIKEY环境变量")

url = "https://mkapi2.dfcfs.com/finskillshub/api/claw/query"
headers = {
    "Content-Type": "application/json",
    "apikey": api_key
}
data = {
    "toolQuery": "东方财富最新价"
}

response = requests.post(url, headers=headers, json=data)
response.raise_for_status()
result = response.json()
print(result)
```

## 异常处理
- 如果数据结果为空，提示用户到东方财富妙想AI查询
- 如果请求失败，检查API Key是否正确，网络是否正常
