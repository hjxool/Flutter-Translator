package words

import (
	"context"

	"github.com/meilisearch/meilisearch-go"
	"gorm.io/gorm"
)

// 典主数据访问接口
type WordRepository interface {
	FindByWord(ctx context.Context, word string) (*Word, error)
}

// ⚠️ 这里是小写私有 避免外部引用 强制使用new来规范创建结构体 避免空指针问题
type wordRepo struct {
	db *gorm.DB
}

// 虽然是通过结构体来调用 但是需要借助函数的提示来规范和限制 避免私自使用结构体或者创建新结构体因为缺乏提示
// 导致一些关键属性未赋值而变成零值 从而出现程序崩溃
func NewWordRepo(db *gorm.DB) WordRepository {
	// 返回值用接口作为类型 目的是为了 信息隐藏 这样外部调用时 看不到具体的结构体名称 只能看到公开的类型名
	// 并不是为了方便后续换源 因为new方法创建结构体实例 本质上已经通过入参限制死了只能用该数据源和结构体
	// 解耦发生在“接收端”（Service 声明我要什么接口），而不是发生在“生成端”（Repository 的 New 方法）
	return &wordRepo{db: db}
}

// 大小写不敏感精准匹配单个单词详情
func (r *wordRepo) FindByWord(ctx context.Context, word string) (*Word, error) {
	var item Word
	err := r.db.WithContext(ctx).Where("word = ? COLLATE NOCASE", word).Take(&item).Error
	if err != nil {
		return nil, err
	}
	return &item, nil
}

// 搜索引擎访问接口
type SearchRepository interface {
	Search(ctx context.Context, query string, limit int64) (any, error)
}
type meiliSearchRepo struct {
	client meilisearch.ServiceManager
	index  string
}

func NewSearchRepo(client meilisearch.ServiceManager) SearchRepository {
	return &meiliSearchRepo{
		client: client,
		index:  "words",
	}
}

// 检索具有拼写纠错能力的前缀联想词条
func (r *meiliSearchRepo) Search(ctx context.Context, query string, limit int64) (any, error) {
	idx := r.client.Index(r.index)
	res, err := idx.SearchWithContext(ctx, query, &meilisearch.SearchRequest{
		Limit: limit,
	})
	if err != nil {
		return nil, err
	}
	// Hits 就是查询结果列表
	return res.Hits, nil
}
