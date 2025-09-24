--支援卡：消耗3点补给，随机制造3张补给2以下的军团单位，让玩家选择1张加入手卡，使其获得效果（部署时不消耗补给）。
local s, id = Import()

function s.initial(c)
	--发动
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗3点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp, 3) end
	Duel.PaySupplyCost(tp, 3)
end

--发动条件：场上有区域卡存在
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.fieldfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

--检查区域卡
function s.fieldfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_FIELD)
end


--随机获取3张不同的军团单位（补给2以下）
function s.get_random_legion_units()
	local sql = string.format([[
		SELECT id FROM datas
		WHERE attribute = %d
		AND level <= 2
		AND type & %d != 0
		AND type & %d = 0
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 3
	]], ATTRIBUTE_EARTH, TYPE_MONSTER, TYPE_TOKEN)

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
	--生成3张随机军团单位
	local card_ids = s.get_random_legion_units()
	if #card_ids == 0 then return end

	--创建临时卡片组用于选择
	local g = Group.CreateGroup()
	for i,id in ipairs(card_ids) do
		local token = Duel.CreateToken(tp, id)
		g:AddCard(token)
	end

	--玩家选择1张
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local sg = g:Select(tp, 1, 1, nil)
	local selected_card = sg:GetFirst()

	if selected_card then
		--将选择的卡片加入手卡
		Duel.SendtoHand(selected_card, nil, REASON_EFFECT)

		--给选中的卡片添加免补给部署效果
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_FREE_DEPLOY)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		selected_card:RegisterEffect(e1)

		--添加客户端hint提示
		local e2 = Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e2:SetDescription(aux.Stringid(id, 0))
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		selected_card:RegisterEffect(e2)
	end
end