--星际陆战队
local s, id = Import()
function s.initial(c)
	--这个怪兽可以直接攻击对方玩家
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e1)
end
