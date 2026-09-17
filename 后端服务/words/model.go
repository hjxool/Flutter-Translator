package words

type Word struct {
	// gorm 标签不需要与表中属性规则一一对应 但必须写明关键tag 否则gorm在组装 结构体->表 时无法正确拼装SQL指令
	ID uint `gorm:"primaryKey" json:"id"`
	// column 用于指定结构体映射到表中哪个列名 可以不写 因为gorm默认映射规则就是首字母转小写
	Word        string `gorm:"column:word" json:"word"`
	Phonetic    string `json:"phonetic"`
	Definition  string `json:"definition"`
	Translation string `json:"translation"`
	Tag         string `json:"tag"`
	Exchange    string `json:"exchange"`
}

// GORM 内部定义了 Tabler 接口 实现 Tabler 接口避免GORM内部调用时找错数据表
// 不过这里其实可以不用实现 因为默认的映射规则是 Word -> words
func (w *Word) TableName() string {
	return "words"
}
