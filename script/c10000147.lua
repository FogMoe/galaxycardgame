--阵列发电站
--消耗1点补给，给双方制造2张地面发电机，放置在支援区。

local s,id=Import()

function s.initial(c)
	-- 发动
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 消耗1点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,1) end
	Duel.PaySupplyCost(tp,1)
end

-- 目标：检查双方是否有空位放置支援卡
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>=2
			and Duel.GetLocationCount(1-tp,LOCATION_SZONE)>=2
	end
end

-- 操作：给双方各制造2张地面发电机放置到支援区
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 检查双方场上是否有足够空位
	local ft1=Duel.GetLocationCount(tp,LOCATION_SZONE)
	local ft2=Duel.GetLocationCount(1-tp,LOCATION_SZONE)

	if ft1<2 or ft2<2 then return end

	-- 给自己放置2张地面发电机
	for i=1,2 do
		local token=Duel.CreateToken(tp,10000014)
		if token then
			-- 将token放置到支援区
			-- MoveToField(Card c, int move_player, int target_player, int dest, int pos, bool enable)
			Duel.MoveToField(token,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
			-- 为这张卡添加3回合后破坏的效果
			s.register_turn_destroy(c,token,tp)
		end
	end

	-- 给对方放置2张地面发电机
	for i=1,2 do
		local token=Duel.CreateToken(1-tp,10000014)
		if token then
			-- 将token放置到对方支援区
			Duel.MoveToField(token,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true)
			-- 为这张卡添加3回合后破坏的效果
			s.register_turn_destroy(c,token,1-tp)
		end
	end
	Duel.BreakEffect()
	Duel.SendtoGrave(e:GetHandler(),REASON_DISCARD)
end

-- 注册回合计数破坏效果
function s.register_turn_destroy(source,target,target_player)
	local e1=Effect.CreateEffect(source)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetRange(LOCATION_SZONE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetOperation(s.turn_destroy_op)
	e1:SetLabel(0)
	e1:SetOwnerPlayer(target_player)
	target:RegisterEffect(e1)
end

-- 回合计数破坏操作
function s.turn_destroy_op(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()
	ct=ct+1
	e:SetLabel(ct)
	-- 在卡片上显示回合计数
	e:GetOwner():SetTurnCounter(ct)
	-- 3回合后破坏
	if ct==3 then
		Duel.Destroy(e:GetHandler(),REASON_EFFECT)
	end
end
