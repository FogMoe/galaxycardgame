--太空粒子风暴
local s,id=Import()
function s.initial(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end
function s.filter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT)
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DAMAGE)
	local g=Duel.SelectTarget(tp,s.filter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,g,1,0,0)
end
function s.op(e,tp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local roll=math.random(1,100)
	local dmg=1
	if roll>70 then
		dmg=2
	end
	Duel.AddHp(tc,-dmg,REASON_EFFECT)
	Duel.BreakEffect()
	Duel.SendtoGrave(e:GetHandler(),REASON_DISCARD)
end
