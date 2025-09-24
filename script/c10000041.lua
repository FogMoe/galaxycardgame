--虫卵
--虫后意志的衍生物，这张卡不能攻击。被破坏时的效果由虫后意志处理。
local s, id = Import()
function s.initial(c)
	--不能攻击
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_ATTACK)
	c:RegisterEffect(e1)
end
