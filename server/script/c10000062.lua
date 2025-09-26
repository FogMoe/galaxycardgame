--共振壳 （永续魔法）支援卡设施
--1发动效果 消耗3补给才能使用。
--2主动1回合1次 自己回合可以使用，破坏自己。
--3永续效果 场上的极光族大型单位变为1/4。
local s, id = Import()
function s.initial(c)
	-- 1.发动效果：消耗3补给才能使用
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.actcost)
	c:RegisterEffect(e1)

	-- 2.主动效果：1回合1次，自己回合可以使用，破坏自己
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- 3.永续效果：场上的极光族大型单位变为1/4
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_SET_ATTACK)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3:SetTarget(s.atktg)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EFFECT_SET_DEFENSE)
	e4:SetValue(4)
	c:RegisterEffect(e4)
end

-- 发动时消耗3补给
function s.actcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp, 3) end
	Duel.PaySupplyCost(tp, 3)
end

-- 破坏条件：自己回合
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

-- 破坏目标
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDestructable() end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
end

-- 破坏操作
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.Destroy(c,REASON_EFFECT)
	end
end

-- 极光族大型单位目标
function s.atktg(e,c)
	return c:IsRace(GALAXY_CATEGORY_AURORA) and c:IsType(TYPE_FUSION)
end
