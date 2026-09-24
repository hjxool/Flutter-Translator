package common

import (
	"os"
	"translator-service/logger"

	"github.com/glebarez/sqlite"
	"github.com/meilisearch/meilisearch-go"
	"go.uber.org/zap"
	"gorm.io/gorm"
	gormLogger "gorm.io/gorm/logger"
)

var (
	DB          *gorm.DB
	MeiliClient meilisearch.ServiceManager
)

func InitDB() {
	var err error
	// 连接 data/ecdict.db
	DB, err = gorm.Open(sqlite.Open("data/ecdict.db"), &gorm.Config{
		// gorm日志模式改为静默
		Logger: gormLogger.Default.LogMode(gormLogger.Silent),
	})
	if err != nil {
		logger.Fatal("连接 SQLite 失败", zap.Error(err))
	}
	// 连接 Meilisearch
	// 读环境变量，没有则回退到 localhost（本地直接 go run 时用）
	meiliURL := os.Getenv("MEILI_URL")
	if meiliURL == "" {
		meiliURL = "http://localhost:7700"
	}
	MeiliClient = meilisearch.New(meiliURL, meilisearch.WithAPIKey("masterKey123"))
	if !MeiliClient.IsHealthy() {
		logger.Warn("警告: Meilisearch 当前不可用，请确保 7700 端口已启动")
	}
}
