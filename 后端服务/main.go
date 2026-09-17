package main

import (
	"time"
	"translator-service/common"
	"translator-service/logger"
	"translator-service/words"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	// 初始化日志系统
	logger.Init()
	// 初始化数据库 (SQLite) 与 Meilisearch 客户端连接
	common.InitDB()
	// 分层初始化：Repository -> Service -> Handler
	wordRepo := words.NewWordRepo(common.DB)
	searchRepo := words.NewSearchRepo(common.MeiliClient)
	wordService := words.NewWordService(wordRepo, searchRepo)
	wordHandler := words.NewWordHandler(wordService)

	router := gin.Default()

	// 配置跨域中间件
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// 业务路由组
	api := router.Group("/api")
	{
		api.GET("/search", wordHandler.SearchHandler)     // 联想纠错搜索
		api.GET("/word/:word", wordHandler.DetailHandler) // 单词完整详情
	}

	logger.Info("词典后端服务运行在 8080 端口...")
	if err := router.Run(":8080"); err != nil {
		logger.Fatal("服务启动失败: " + err.Error())
	}
}
