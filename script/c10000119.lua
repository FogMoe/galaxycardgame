--深根连接
--消耗2点补给，抽1张卡，若你场上有植物类单位，则改为抽2张。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--补给成本
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

--植物类单位过滤器
function s.filter(c)
	return c:IsFaceup() and c:IsRace(RACE_PLANT) and c:IsType(GALAXY_TYPE_UNIT)
end

--目标检查
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=1
	if Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) then
		ct=2
	end
	if chk==0 then return Duel.IsPlayerCanDraw(tp,ct) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(ct)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	local ct=1
	if Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) then
		ct=2
	end
	Duel.Draw(p,ct,REASON_EFFECT)
end
