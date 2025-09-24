--能量崩塌
--消耗3点补给，摧毁场上所有设施卡。每摧毁1张，获得1点高能计数标记。
local s, id = Import()
function s.initial(c)
	-- 发动效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 消耗：3点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp, 3) end
	Duel.PaySupplyCost(tp, 3)
end

-- 设施卡过滤器（永续魔法/陷阱）
function s.desfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_CONTINUOUS) and c:IsDestructable()
end

-- 目标：场上所有设施卡
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,g:GetCount(),0,0)
end

-- 检查能放置高能计数器的卡片
function s.counterfilter(c)
	return c:IsFaceup() and c:IsCanAddCounter(0x1042,1)
end

-- 操作：摧毁所有设施卡，每摧毁1张获得1点高能计数标记
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if g:GetCount()>0 then
		local ct=Duel.Destroy(g,REASON_EFFECT)
		if ct>0 then
			-- 摧毁成功后，获得对应数量的高能计数标记
			local counter_cards=Duel.GetMatchingGroup(s.counterfilter,tp,LOCATION_ONFIELD,0,nil)
			if counter_cards:GetCount()>0 then
				-- 如果有多张可放置计数器的卡，让玩家选择
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
				local target=counter_cards:Select(tp,1,1,nil):GetFirst()
				if target then
					target:AddCounter(0x1042,ct,true)
				end
			end
		end
	end
end