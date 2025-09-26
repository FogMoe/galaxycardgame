--碎星者
local s, id = Import()
function s.initial(c)
	--这张卡特殊召唤成功时发动，破坏场上的全部场地卡。
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
function s.filter(c)
	return c:IsType(TYPE_FIELD)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil) end
	local sg=Duel.GetMatchingGroup(s.filter,tp,LOCATION_FZONE,LOCATION_FZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,sg:GetCount(),0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local sg=Duel.GetMatchingGroup(s.filter,tp,LOCATION_FZONE,LOCATION_FZONE,nil)
	if sg:GetCount()>0 then
		Duel.Destroy(sg,REASON_EFFECT)
	end
end
