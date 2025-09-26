--基因收割者
--弃牌区中每有一张节肢类单位就获得+1战斗力。
local s, id = Import()
function s.initial(c)
	--根据弃牌区节肢类单位数量增加攻击力
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.atkval(e,c)
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.filter,tp,GALAXY_LOCATION_DISCARD,0,nil)
	return g:GetCount() * 1
end
