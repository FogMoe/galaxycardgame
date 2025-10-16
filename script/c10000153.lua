--银河曼德拉草
local s,id=Import()
function s.initial(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(GALAXY_EVENT_HP_DAMAGE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	if c:GetFlagEffect(id)~=0 then
		c:ResetFlagEffect(id)
		return
	end
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
	Duel.AddHp(c,-1,REASON_EFFECT)
end
