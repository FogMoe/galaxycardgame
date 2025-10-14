--人类创世方舟
--大型单位，开局时从特殊卡组展示，制造10张星际宣言加入卡组，在本局对战中使自己只能部署人类单位（本效果不叠加）。
--开局展示效果由utility.lua的Galaxy.SummonForStart统一处理

local s,id=Import()

function s.initial(c)
	-- 开局展示效果已在utility.lua中统一处理
	-- 本卡无其他特殊效果
end
