--意志同化
--支援卡，消耗2点补给，失去5点影响力，从卡组把1张节肢类单位加入手卡。如果你的影响力低于敌人，部署那张单位的补给减少1点。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) and Duel.CheckLPCost(tp,5) end
	Duel.PaySupplyCost(tp,2)
	Duel.PayLPCost(tp,5)
end

function s.filter(c)
	return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT) and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		--Duel.ConfirmCards(1-tp,g)

		--如果影响力低于敌人，检索到的单位补给减少1点
		if Duel.GetLP(tp) < Duel.GetLP(1-tp) then
			local tc=g:GetFirst()
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_LEVEL)
			e1:SetValue(-1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			--添加客户端hint提示
			local e2 = Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e2:SetDescription(aux.Stringid(id, 0))
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end
