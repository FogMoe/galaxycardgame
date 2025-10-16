--放射性荆棘
local s,id=Import()
function s.initial(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SHIELD)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.spmcon)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
function s.spmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsReason(REASON_DESTROY) and not c:IsReason(REASON_RULE) then return false end
	if not c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE) then return false end
	local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	if hand:GetCount()==0 then return false end
	return hand:FilterCount(Card.IsType,nil,GALAXY_TYPE_UNIT)==hand:GetCount()
		and hand:FilterCount(Card.IsRace,nil,RACE_PLANT)==hand:GetCount()
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetMaxSupply(tp)>=10 then return end
	Duel.AddMaxSupply(tp,1)
end
