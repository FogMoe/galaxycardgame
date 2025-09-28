--不会被其他卡的效果影响。
local s, id = Import()
function s.initial(c)
	--效果免疫：不会被其他卡的效果影响
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
end
function s.efilter(e,re)
	return re:GetHandler()~=e:GetHandler()
end