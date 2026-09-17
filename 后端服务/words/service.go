package words

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

// 领域通用错误枚举
var (
	ErrWordNotFound = errors.New("未找到该单词释义")
)

type WordService interface {
	SearchWords(ctx context.Context, query string) (any, error)
	GetWordDetail(ctx context.Context, word string) (*Word, error)
}
type wordSev struct {
	wordRepo   WordRepository
	searchRepo SearchRepository
}

func NewWordService(wordRepo WordRepository, searchRepo SearchRepository) WordService {
	return &wordSev{
		wordRepo:   wordRepo,
		searchRepo: searchRepo,
	}
}

// 搜索建议联想（默认取前 20 条）
func (s *wordSev) SearchWords(ctx context.Context, query string) (any, error) {
	if query == "" {
		return []any{}, nil
	}
	return s.searchRepo.Search(ctx, query, 20)
}

// 获取指定单词的完整词典详情
func (s *wordSev) GetWordDetail(ctx context.Context, word string) (*Word, error) {
	item, err := s.wordRepo.FindByWord(ctx, word)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrWordNotFound
		}
		return nil, err
	}
	return item, nil
}
