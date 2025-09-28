--出场时获得潜行效果
local s, id = Import()
function s.initial(c)
	--出场时自动获得潜行效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.stealthop)
	c:RegisterEffect(e1)
end


--获得潜行效果
function s.stealthop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_MZONE) then return end
	--没有才会获得潜行效果
	if c:IsHasEffect(EFFECT_STEALTH) then return end
	--潜行效果
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_STEALTH)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)

	--立即添加潜行显示（手动调用显示函数）
	if not c:IsHasEffect(EFFECT_STEALTH_HINT) then
		local e2 = Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(10000077,3)) --潜行显示提示文本
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_STEALTH_HINT) --潜行显示标识码
		e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CLIENT_HINT)
		e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		e2:SetReset(RESET_EVENT + RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
end