package words

import (
	"errors"
	"net/http"
	"strings"
	"translator-service/common"

	"github.com/gin-gonic/gin"
)

// 因为Handler已经是最外层 无需抽象接口封装来支持替换数据源和Mock 直接注册给Gin路由
// 因此new方法返回的直接是结构体 而小写的私有化属性无法暴露给外部 因此此处结构体必须大写
// 但内部属性依然用小写 是为了防止外部直接修改内部状态 强制通过new方法作为唯一入口
type WordHandler struct {
	service WordService
}

// 安全创建结构体的唯一入口
func NewWordHandler(service WordService) *WordHandler {
	return &WordHandler{service: service}
}

// 模糊纠错 + 前缀即时联想
func (h *WordHandler) SearchHandler(c *gin.Context) {
	// TrimSpace 裁掉字符串开头和结尾的所有空白符号
	keyword := strings.TrimSpace(c.Query("keyword"))
	hits, err := h.service.SearchWords(c.Request.Context(), keyword)
	if err != nil {
		common.ErrorResponse(c, http.StatusBadRequest, "检索服务异常: "+err.Error())
		return
	}
	common.SuccessResponse(c, hits)
}

// 获取单词完整详情
func (h *WordHandler) DetailHandler(c *gin.Context) {
	// Param 是通过GET /api/words/apple形式传参 通过 :word 形式捕获
	word := strings.TrimSpace(c.Param("word"))
	if word == "" {
		common.ErrorResponse(c, http.StatusBadRequest, "查询单词不能为空")
		return
	}
	detail, err := h.service.GetWordDetail(c.Request.Context(), word)
	if err != nil {
		if errors.Is(err, ErrWordNotFound) {
			common.ErrorResponse(c, http.StatusNotFound, err.Error())
		} else {
			common.ErrorResponse(c, http.StatusInternalServerError, "数据库查询异常")
		}
		return
	}
	common.SuccessResponse(c, detail)
}
