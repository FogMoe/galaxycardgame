--虚空孵化舱 支援卡
--消耗5点补给，制造8张0/1的幼体寄生虫加入对方卡组
local s, id = Import()

function s.initial(c)
	--发动
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗5点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp, 5) end
	Duel.PaySupplyCost(tp, 5)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--创建8张幼体寄生虫token（需要先创建对应的卡片ID）
	local g = Group.CreateGroup()
	for i = 1, 8 do
		-- 假设幼体寄生虫的ID是10000087，如果没有则需要先创建
		local token = Duel.CreateToken(1-tp, 10000087)
		g:AddCard(token)
	end

	if #g > 0 then
		--将token加入对方卡组并洗切
		Duel.ConfirmCards(1-tp, g)
		Duel.SendtoDeck(g, 1-tp, 2, REASON_EFFECT)
	end
end