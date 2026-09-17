// 把 SQLite 词条批量推送到 Meilisearch 的同步脚本
// 不同于python一次性转换 这里用go是因为这是工程中的一部分
package main

import (
	"time"
	"translator-service/common"
	"translator-service/logger"
	"translator-service/words"

	"github.com/meilisearch/meilisearch-go"
	"go.uber.org/zap"
)

// ⚠️ ECDICT 有 77 万条数据，不能一次性全部加载到内存。采用分批分页的方式推送到Meilisearch
func main() {
	logger.Init()
	common.InitDB()
	client := common.MeiliClient
	// 在本地 Go 内存中构造一个 *meilisearch.Index 结构体指针，指定名字叫 "words"，并没有向网络发包
	// 这类倒排索引数据库的 索引Index 即关系型数据库中的表
	index := client.Index("words")
	logger.Info("正在配置 Meilisearch 索引与纠错规则...")
	// 向 Meilisearch 服务端发送 HTTP 请求，正式建立名为 "words" 且主键为 "id" 的索引
	_, _ = client.CreateIndex(&meilisearch.IndexConfig{
		// Uid 相当于表名
		Uid:        "words",
		PrimaryKey: "id",
	})
	// 通过前面获取的 index 句柄，向刚刚创建好的索引推送配置规则
	// 配置检索字段（只检索 word 和 translation，加速查询）否则会对存入的每一个字段建立倒排索引
	// UpdateSearchableAttributes 中越靠前的字段匹配权重越高
	_, _ = index.UpdateSearchableAttributes(&[]string{"word", "translation"})
	// 开启并优化 Typo Tolerance（错别字容错），针对 OCR 取词场景非常有用！
	_, _ = index.UpdateTypoTolerance(&meilisearch.TypoTolerance{
		Enabled: true,
		MinWordSizeForTypos: meilisearch.MinWordSizeForTypos{
			// 长度 >=3 容许错 1 个字母 (如 thnk -> think)
			OneTypo: 3,
			// 长度 >=7 容许错 2 个字母 (如 resgister -> register)
			TwoTypos: 7,
		},
	})
	logger.Info("开始从 SQLite 同步数据到 Meilisearch...")
	start := time.Now()
	batchSize := 5000
	var offset int
	total := 0
	for {
		var words []words.Word
		// 分批读取，避免内存撑爆
		err := common.DB.Select("id", "word", "phonetic", "translation", "tag").Limit(batchSize).Offset(offset).Find(&words).Error
		if err != nil || len(words) == 0 {
			// 报错或者查询结果为空则跳出循环
			break
		}
		// 批量推送到 Meilisearch
		_, err = index.AddDocuments(words, nil)
		if err != nil {
			// 只代表任务已成功提交到队列 Meilisearch是异步队列任务
			logger.Fatal("推送文档失败", zap.Error(err))
		}
		total += len(words)
		offset += batchSize
		logger.Info("同步进度", zap.Int("total", total))
	}
	logger.Info("同步完成", zap.Int("total", total), zap.Duration("cost", time.Since(start)))
}
