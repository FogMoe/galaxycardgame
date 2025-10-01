--盖亚 场地魔法
--双方部署攻击力和生命值相等的军团单位不需要消耗补给（获得一个CODE=EFFECT_FREE_DEPLOY)。
local s, id = Import()
function s.initial(c)
	--激活
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--双方军团单位攻防相等时免费部署
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_FREE_DEPLOY)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_HAND,LOCATION_HAND)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.freetg)
	c:RegisterEffect(e2)
end

--免费部署目标（攻击力等于生命值的军团单位）
function s.freetg(e,c)
	return c:GetAttack()==c:GetHp() and c:IsGalaxyProperty(GALAXY_PROPERTY_LEGION) and c:GetSupplyCost()<=3
end
