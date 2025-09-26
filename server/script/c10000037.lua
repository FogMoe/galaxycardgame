--幼虫工兵
--部署时（战吼）（特殊召唤时发动）如果手牌中有其他节肢类单位，这张卡获得+1/+2（战斗力/生命值）。
local s, id = Import()
function s.initial(c)
	--部署时（特殊召唤时）发动的效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--检查手牌中是否有其他节肢类单位
	return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND,0,1,c)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		--战斗力+1
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		--生命值+2
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		e2:SetValue(2)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
end
