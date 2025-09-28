--支援卡：消耗3点补给，选择一个友方哺乳类单位，使其获得+2/+2和免疫1次战斗伤害。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗3点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,3) end
	Duel.PaySupplyCost(tp,3)
end

--友方哺乳类单位过滤器
function s.filter(c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_MAMMAL) and c:IsType(GALAXY_TYPE_UNIT)
end

--目标选择
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,1,0,0)
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		--攻击力+2
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(2)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		--防御力+2
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_HP)
		tc:RegisterEffect(e2)
		if not tc:IsHasEffect(EFFECT_SHIELD) and not tc:IsHasEffect(EFFECT_SHIELD_HINT) then
			--免疫1次战斗伤害（护盾效果）
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_SHIELD)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e3)
			--显示护盾效果提示
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetDescription(aux.Stringid(id,1))
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
			e4:SetRange(GALAXY_LOCATION_UNIT_ZONE)
			e4:SetReset(RESET_EVENT+RESETS_STANDARD)
			e4:SetCode(EFFECT_SHIELD_HINT) --护盾显示标识码
			tc:RegisterEffect(e4)
		end
	end
end
