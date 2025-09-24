--刀锋猎手
--每有一个其他友方节肢类单位，获得+1/+0。
local s, id = Import()
function s.initial(c)
	--冲锋能力
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_RUSH)
	c:RegisterEffect(e1)

	--基于其他节肢类单位的攻击力加成
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
end

function s.atkfilter(c,original)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
		and c:IsType(GALAXY_TYPE_UNIT) and c~=original
end

function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),GALAXY_LOCATION_UNIT_ZONE,0,c)*1
end