--尸宴仪式
--消耗5点补给，制造3张残骸碎片，加入卡组，在本局对战中每当自己卡组少于3张卡时，随机制造1张亡灵类单位卡加入卡组底部（每回合1次，此效果不叠加）。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗5点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,5) end
	Duel.PaySupplyCost(tp,5)
end

--目标
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,0)
end

--随机获取亡灵类单位
function s.get_random_undead_unit()
	local sql = string.format([[
		SELECT id FROM datas
		WHERE race = %d
		AND type & %d != 0
		AND type & %d = 0
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 1
	]], RACE_ZOMBIE, TYPE_MONSTER, TYPE_TOKEN)

	local results = Duel.QueryDatabase(sql)
	if results and not results.error and #results > 0 then
		return results[1].id
	end
	return nil
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--制造3张残骸碎片加入卡组
	local g=Group.CreateGroup()
	for i=1,3 do
		local token=Duel.CreateToken(tp,10000129)
		g:AddCard(token)
	end

	if #g>0 then
		Duel.ConfirmCards(1-tp,g)
		Duel.SendtoDeck(g,tp,2,REASON_EFFECT)
	end

	--注册持续监控效果（整局有效，使用ADJUST时点）
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ADJUST)
	e1:SetCondition(s.checkcon)
	e1:SetOperation(s.checkop)
	Duel.RegisterEffect(e1,tp)
end

--检查条件：卡组少于3张且本回合未触发
function s.checkcon(e,tp,eg,ep,ev,re,r,rp)
	local deck_count=Duel.GetFieldGroupCount(tp,GALAXY_LOCATION_BASIC_DECK,0)
	return deck_count<3
		and s.get_random_undead_unit()~=nil
		and not Duel.IsPlayerAffectedByEffect(tp,id)
end

--检查操作：制造亡灵类单位加入卡组底部
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local deck_count=Duel.GetFieldGroupCount(tp,GALAXY_LOCATION_BASIC_DECK,0)
	if deck_count>=3 then return end

	local card_id=s.get_random_undead_unit()
	if card_id then
		local token=Duel.CreateToken(tp,card_id)
		if token then
			Duel.Hint(HINT_CARD,1-tp,id)
			Duel.SendtoDeck(token,tp,1,REASON_EFFECT)

			--注册本回合已触发的标记，避免重复触发
			local e_flag=Effect.CreateEffect(e:GetHandler())
			e_flag:SetType(EFFECT_TYPE_FIELD)
			e_flag:SetCode(id)
			e_flag:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e_flag:SetTargetRange(1,0)
			e_flag:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e_flag,tp)
		end
	end
end
