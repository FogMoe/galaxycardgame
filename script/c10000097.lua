--双重战斗者
--这张卡在战斗阶段可以作2次攻击
local s, id = Import()
function s.initial(c)
	--可以进行双重攻击
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
	e1:SetValue(1) --额外攻击1次，总共2次攻击
	c:RegisterEffect(e1)
end