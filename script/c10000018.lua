--太阳系先锋
local s, id = Import()
function s.initial(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_RUSH)
	c:RegisterEffect(e1)
end