--物质瓦解射线
--消耗4点补给，选择1个敌方单位，移出游戏外，给能放置的1个卡放1高能计数标记。
local s, id = Import()
function s.initial(c)
	-- 发动效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 消耗：4点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp, 4) end
	Duel.PaySupplyCost(tp, 4)
end

-- 目标：选择1个敌方单位
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

-- 检查能放置高能计数器的卡片
function s.counterfilter(c)
	return c:IsFaceup() and c:IsCanAddCounter(0x1042,1)
end

-- 操作：移出游戏外，并给能放置的卡放置高能计数标记
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)~=0 then
			-- 移出成功后，检查能放置计数器的卡片
			local g=Duel.GetMatchingGroup(s.counterfilter,tp,LOCATION_ONFIELD,0,nil)
			if g:GetCount()>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
				local sg=g:Select(tp,1,1,nil)
				if sg:GetCount()>0 then
					local counter_target=sg:GetFirst()
					counter_target:AddCounter(0x1042,1,true)
				end
			end
		end
	end
end
