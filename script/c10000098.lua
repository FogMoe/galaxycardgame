--防护兵
--GCG效果：1保护，2护盾
local s, id = Import()
function s.initial(c)
	--保护效果
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)

	--护盾效果
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SHIELD)
	c:RegisterEffect(e2)
end