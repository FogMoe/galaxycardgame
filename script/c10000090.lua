--不会被对方卡的效果影响。
local s, id = Import()
function s.initial(c)
	--效果免疫：不会被对方卡的效果影响
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
end
function s.efilter(e,re)
	local rc=re:GetHandler()
	if not rc then return false end
	-- 只免疫在常规游戏位置的对方卡（避免免疫系统规则）
	if not rc:IsLocation(LOCATION_ONFIELD) then
		return false
	end
	return rc:IsControler(1-e:GetHandlerPlayer()) and rc:IsType(GALAXY_TYPE_SUPPORT+GALAXY_TYPE_UNIT+GALAXY_TYPE_TACTICS)
end