--地球联盟步兵
local s, id = Import()
function s.initial(c)
	--这个怪兽对对方造成lp伤害时发动，自己回复造成的lp伤害值
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_BATTLE_DAMAGE)
	e1:SetCondition(s.reccon)
	e1:SetOperation(s.recop)
	c:RegisterEffect(e1)
end

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Recover(tp,ev,REASON_EFFECT)
end
