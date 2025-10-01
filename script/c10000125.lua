--根网集群
--消耗5点补给可以使用，3个自己回合后的自己休整阶段破坏。
--在你的补给阶段时，若你控制至少2个植物类单位，随机制造1个植物类单位并部署。
local s, id = Import()
function s.initial(c)
	--激活效果：消耗5点补给
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCost(s.actcost)
	e0:SetOperation(s.actop)
	c:RegisterEffect(e0)

	--补给阶段效果：控制2个植物时随机部署1个植物单位
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_DRAW)
	e1:SetRange(GALAXY_LOCATION_SUPPORT_ZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--休整阶段检查回合计数器并破坏
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(GALAXY_LOCATION_SUPPORT_ZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.descon)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

--激活成本：5点补给
function s.actcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,5) end
	Duel.PaySupplyCost(tp,5)
end

--激活操作：设置回合计数器为3
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--设置3回合计数器
	c:SetTurnCounter(3)
	--客户端提示
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,2))
end

--随机获取植物类单位
function s.get_random_plant_unit()
	local sql = string.format([[
		SELECT id FROM datas
		WHERE race = %d
		AND type & %d != 0
		AND type & %d = 0
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 1
	]], RACE_PLANT, TYPE_MONSTER, TYPE_TOKEN)

	local results = Duel.QueryDatabase(sql)
	if results and not results.error and #results > 0 then
		return results[1].id
	end
	return nil
end

--补给阶段条件：是自己回合且控制至少2个植物类单位
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
		and Duel.GetMatchingGroupCount(s.plantfilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)>=2
		and Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and s.get_random_plant_unit()~=nil
end

--植物类单位过滤器
function s.plantfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_PLANT) and c:IsType(GALAXY_TYPE_UNIT)
end

--特殊召唤目标
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.spcon(e,tp,eg,ep,ev,re,r,rp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

--特殊召唤操作
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return end

	local card_id = s.get_random_plant_unit()
	if card_id then
		local token = Duel.CreateToken(tp, card_id)
		if token then
			Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
		end
	end
end

--破坏条件：自己的休整阶段
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetTurnPlayer()~=tp then return false end

	--递减回合计数器
	local ct=c:GetTurnCounter()
	if ct>0 then
		ct=ct-1
		c:SetTurnCounter(ct)
	end

	--当计数器为0时破坏
	return ct==0
end

--破坏操作
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.Destroy(c,REASON_EFFECT)
	end
end
