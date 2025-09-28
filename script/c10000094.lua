--对敌方单位造成的战斗伤害额外增加目标的当前生命值。（致命effectcode）
--被攻击时，将生命值恢复到最大上限。（getmaxhp函数）
--仅限1次，恢复生命值时，将补给恢复到最大上限。
local s, id = Import()
function s.initial(c)
	--致命效果：战斗伤害额外增加目标当前生命值
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LETHAL)
	c:RegisterEffect(e1)

	--被攻击时，生命值恢复到最大上限
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DEFCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_BE_BATTLE_TARGET)
	e2:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e2:SetCountLimit(1)
	--生命不满才能发动
	e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		return c:IsLocation(LOCATION_MZONE) and c:GetHp()<c:GetMaxHp()
	end)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)

	--仅限1次，恢复生命值时，选择将补给恢复到最大上限
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(GALAXY_EVENT_HP_RECOVER)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e3:SetCountLimit(1)
	e3:SetCondition(s.supplycon)
	e3:SetOperation(s.supplyop)
	c:RegisterEffect(e3)
end

--恢复生命值到最大上限
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_MZONE) then return end

	--添加已使用效果的客户端提示
	c:RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))

	--获取最大生命值并恢复
	local max_hp = c:GetMaxHp()
	local current_hp = c:GetHp()
	if max_hp > current_hp and max_hp>0 and current_hp>0 then
		local heal_amount = max_hp - current_hp
		Duel.AddHp(c, heal_amount, REASON_EFFECT)
	end
end

--检查生命值恢复是否涉及自己并且补给没满
function s.supplycon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsLocation(LOCATION_MZONE) then return false end
	--检查恢复的目标中是否包含自己
	return eg:IsContains(c) and Duel.GetSupply(tp)<Duel.GetMaxSupply(tp)
end

--将补给恢复到最大上限
function s.supplyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_MZONE) then return end

	--添加已使用效果的客户端提示
	c:RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,2))

	--获取最大补给并恢复
	local max_supply = Duel.GetMaxSupply(tp)
	local current_supply = Duel.GetSupply(tp)
	if max_supply > current_supply then
		Duel.SetSupply(tp, max_supply, max_supply)
	end
end