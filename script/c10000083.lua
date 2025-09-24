--消耗2点补给，随机制造2张不同的区域支援卡，选择1张加入手卡。
local s, id = Import()

function s.initial(c)
	--发动
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗2点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp, 2) end
	Duel.PaySupplyCost(tp, 2)
end

--随机获取2张不同的区域支援卡
function s.get_random_field_cards()
	local sql = string.format([[
		SELECT id FROM datas
		WHERE type & %d != 0
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 2
	]], TYPE_FIELD)

	local results = Duel.QueryDatabase(sql)
	local cards = {}
	if results and not results.error then
		for i = 1, #results do
			table.insert(cards, results[i].id)
		end
	end
	return cards
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--生成2张随机区域支援卡
	local card_ids = s.get_random_field_cards()
	if #card_ids == 0 then return end

	--创建临时卡片组用于选择
	local g = Group.CreateGroup()
	for i,id in ipairs(card_ids) do
		local token = Duel.CreateToken(tp, id)
		g:AddCard(token)
	end
	Duel.ConfirmCards(1-tp, g)
	--玩家选择1张
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local sg = g:Select(tp, 1, 1, nil)
	local selected_card = sg:GetFirst()

	if selected_card then
		--将选择的卡片加入手卡
		Duel.SendtoHand(selected_card, nil, REASON_EFFECT)
		Duel.ConfirmCards(1-tp, selected_card)
	end

	--将剩下的卡片加入对方卡组
	local remaining = g - sg
	if #remaining > 0 then
		Duel.ConfirmCards(1-tp, remaining)
		Duel.SendtoDeck(remaining, 1-tp, 2, REASON_EFFECT)
	end
end