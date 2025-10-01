--星贝护壳
--消耗2点补给，使1个拥有效果（保护友方单位）的单位获得效果（免疫1次伤害），若目标是软体类单位，则额外回复1点生命。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗2点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

--拥有保护效果的友方单位过滤器
function s.filter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT) and c:IsHasEffect(EFFECT_PROTECT)
end

--目标选择
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,GALAXY_LOCATION_UNIT_ZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,GALAXY_LOCATION_UNIT_ZONE,1,1,nil)
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	--给目标添加护盾效果（免疫1次伤害）
	if not tc:IsHasEffect(EFFECT_SHIELD) and not tc:IsHasEffect(EFFECT_SHIELD_HINT) then
		--护盾效果
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SHIELD)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)

		--护盾显示提示
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetDescription(aux.Stringid(10000077,2))
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		e2:SetCode(EFFECT_SHIELD_HINT)
		tc:RegisterEffect(e2)
	end

	--如果目标是软体类单位，额外回复1点生命
	if tc:IsGalaxyCategory(GALAXY_CATEGORY_MOLLUSK) then
		Duel.AddHp(tc, 1, REASON_EFFECT)
	end
end
