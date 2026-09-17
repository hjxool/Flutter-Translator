package common

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Response[T any] struct {
	Head struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"head"`
	Body T `json:"body"`
}

func SuccessResponse[T any](c *gin.Context, body T) {
	res := Response[T]{}
	res.Head.Code = http.StatusOK
	res.Head.Message = "success"
	res.Body = body
	c.JSON(http.StatusOK, res)
}

func ErrorResponse(c *gin.Context, code int, msg string) {
	res := Response[any]{}
	res.Head.Code = code
	res.Head.Message = msg
	res.Body = nil
	c.JSON(http.StatusOK, res)
}
