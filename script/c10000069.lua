--等离子爪突击兵
local s, id = Import()
function s.initial(c)
	--在部署的回合就可以攻击（疾驰效果）
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_RUSH)
	c:RegisterEffect(e1)
	--当你控制其他哺乳类单位时，+1战斗力
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.mammalcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)
end

--哺乳类过滤器
function s.mammalfilter(c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_MAMMAL) and c:IsType(GALAXY_TYPE_UNIT)
end

--哺乳类条件检查
function s.mammalcon(e)
	return Duel.IsExistingMatchingCard(s.mammalfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,e:GetHandler())
end