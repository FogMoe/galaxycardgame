--支援卡消耗1点补给，制造1张补给3以下的攻击力和生命值相等的军团单位（从数据库中随机选择符合条件的卡然后通过Createtoken给玩家加入手卡）。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--随机获取符合条件的军团单位（使用数据库查询）
function Galaxy.GetRandomLegionUnit(max_cost)
	local sql = string.format([[
		SELECT id FROM datas
		WHERE atk = def
		AND attribute = %d
		AND level <= %d
		AND type & %d != 0
		AND type & %d = 0
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 1
	]], ATTRIBUTE_EARTH, max_cost, TYPE_MONSTER, TYPE_TOKEN)

	local results = Duel.QueryDatabase(sql)
	if results and not results.error and #results > 0 then
		return results[1].id
	end
	return nil
end

--消耗1点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,1) end
	Duel.PaySupplyCost(tp,1)
end

--目标
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local card_id = Galaxy.GetRandomLegionUnit(3)
		return card_id~=nil
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,0)
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local card_id = Galaxy.GetRandomLegionUnit(3)
	if card_id then
		local token = Duel.CreateToken(tp, card_id)
		if token then
			Duel.SendtoHand(token,nil,REASON_EFFECT)
		end
	end
end