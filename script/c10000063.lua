--高能区域 场地卡
--在场上的高能指示物5以上时才能使用。
--在场上的高能指示物4以下时此卡破坏。
--全场补给5以上的单位获得+4生命值。
local s, id = Import()
function s.initial(c)
	-- 发动效果：需要场上高能指示物5以上
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	c:RegisterEffect(e1)

	-- 自毁条件：场上高能指示物4以下时破坏
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCode(EFFECT_SELF_DESTROY)
	e2:SetCondition(s.descon)
	c:RegisterEffect(e2)

	-- 永续效果：补给5以上的单位获得+4生命值
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3:SetTarget(s.deftg)
	e3:SetValue(4)
	c:RegisterEffect(e3)
end

-- 计算场上所有高能计数器总数
function s.get_total_counters(tp)
	local total = 0
	-- 检查双方场地的所有卡片
	local g = Duel.GetFieldGroup(tp,LOCATION_ONFIELD,LOCATION_ONFIELD)
	local tc = g:GetFirst()
	while tc do
		if tc:GetCounter(0x1042) > 0 then
			total = total + tc:GetCounter(0x1042)
		end
		tc = g:GetNext()
	end
	return total
end

-- 发动条件：场上高能指示物5以上
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return s.get_total_counters(tp) >= 5
end

-- 自毁条件：场上高能指示物4以下
function s.descon(e)
	local tp = e:GetHandlerPlayer()
	return s.get_total_counters(tp) <= 4
end

-- 补给5以上单位目标
function s.deftg(e,c)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:GetLevel() >= 5
end