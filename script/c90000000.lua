local s,id=Import()
function s.initial(c)
	--每回合一次：消耗2补给，回复友方人类单位2点生命值
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(GALAXY_LOCATION_SUPPORT_ZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1)
	e1:SetCost(s.hpcost)
	e1:SetTarget(s.hptg)
	e1:SetOperation(s.hpop)
	c:RegisterEffect(e1)
end

function s.hpcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

function s.hpfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsType(GALAXY_TYPE_UNIT) and c:IsGalaxyCategory(GALAXY_CATEGORY_HUMAN)
end

function s.hptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and s.hpfilter(chkc,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.hpfilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.hpfilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,1,nil,tp)
end

function s.hpop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then
		return
	end
	Duel.AddHp(tc,2,REASON_EFFECT)
end
