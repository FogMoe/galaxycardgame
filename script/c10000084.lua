--战争机甲库 支援卡
--消耗4点补给，制造5张3/1的战争机甲（地，机械，补给2）加入卡组
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

--消耗4点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp, 4) end
	Duel.PaySupplyCost(tp, 4)
end


function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--创建5张战争机甲token
	local g = Group.CreateGroup()
	for i = 1, 5 do
		local token = Duel.CreateToken(tp, 10000085)
		g:AddCard(token)
	end

	if #g > 0 then
		--将token加入卡组并洗切
        Duel.ConfirmCards(1-tp, g)
		Duel.SendtoDeck(g, tp, 2, REASON_EFFECT)
	end
end