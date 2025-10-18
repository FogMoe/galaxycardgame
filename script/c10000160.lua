--寄生植物
--这个单位在场时，敌方手卡中补给1的单位补给增加1点。
local s,id = Import()
function s.initial(c)
	--闪击：部署回合可攻击单位但不能直击
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_RUSH_R)
	c:RegisterEffect(e1)

	--敌方手卡中等级1的单位等级+1
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_LEVEL)
	e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e2:SetTargetRange(0,LOCATION_HAND)
	e2:SetTarget(s.lvtg)
	e2:SetValue(1)
	c:RegisterEffect(e2)
end

function s.lvtg(e,c)
	return c:IsType(GALAXY_TYPE_UNIT) and c:IsLevel(1)
end
