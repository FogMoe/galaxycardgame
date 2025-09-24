--铁锤团
local s, id = Import()
function s.initial(c)
	--这张卡可以向对方全部怪兽各做一次攻击。
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--这张卡在自己补给8以上时才可以特殊召唤
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetCondition(s.con2)
	c:RegisterEffect(e2)
end
--额外条件：补给必须 >= 8
function s.con2(e)
	return Duel.GetSupply(e:GetHandlerPlayer()) < 8
end
