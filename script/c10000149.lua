--进化飞升机械体
--单位：在场时，场上所有单位变为机械类。

local s,id=Import()

function s.initial(c)
	-- 在场时，场上所有单位变为机械类
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_RACE)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetTargetRange(GALAXY_LOCATION_UNIT_ZONE,GALAXY_LOCATION_UNIT_ZONE)
	e1:SetValue(RACE_MACHINE)
	c:RegisterEffect(e1)
end
