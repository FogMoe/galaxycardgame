--恒星风回流
--每有一张友方卡被破坏，获得1点高能计数标记0x1042。
local s, id = Import()
function s.initial(c)
	-- 启用高能计数器
	c:EnableCounterPermit(0x1042) -- 高能计数器

	-- 激活
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- 友方卡被破坏时增加计数器
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCondition(s.ctcon)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
end

-- 检查是否为友方卡被破坏
function s.ctfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsReason(REASON_DESTROY)
end

function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ctfilter,1,nil,tp)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.ctfilter,nil,tp)
	if ct>0 then
		e:GetHandler():AddCounter(0x1042,ct,true)
	end
end