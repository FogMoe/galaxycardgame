--极光"蚊笼"
--1当场上存在"共振壳"或"高能区域"时才可以部署，这个大型单位可以自行部署。
--2"共振壳"不存在于场上时，自己回合休整阶段，如果对方场上存在单位，则对其场上生命值最低的单位造成X点伤害，并恢复2点生命值（X为这张卡的原本生命值-当前生命值）。
--3保护友方单位。
--4当场上不存在"共振壳"或"高能区域"时破坏。
--5在场上被破坏时对全场单位造成这张卡剩余生命值的伤害。
local s, id = Import()
function s.initial(c)
	-- 1.召唤条件：当场上存在"共振壳"或"高能区域"时才可以被召唤
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetCondition(s.splimcon)
	c:RegisterEffect(e1)

	-- 特殊召唤方式（从额外卡组特殊召唤）
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	e2:SetValue(SUMMON_VALUE_SELF)
	c:RegisterEffect(e2)

	-- 4.自毁条件：当场上不存在"共振壳"或"高能区域"时破坏
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_SELF_DESTROY)
	e3:SetCondition(s.descon)
	c:RegisterEffect(e3)

	-- 3.保护效果：对方单位必须优先攻击这张卡
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e4)

	-- 2.休整阶段效果："共振壳"不存在时，伤害对方生命值最低单位并恢复自身
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DEFCHANGE)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetCondition(s.draincon)
	e5:SetTarget(s.draintg)
	e5:SetOperation(s.drainop)
	c:RegisterEffect(e5)

	-- 5.被破坏时对全场单位造成伤害
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DAMAGE)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_DESTROYED)
	e6:SetCondition(s.damcon)
	e6:SetOperation(s.damop)
	c:RegisterEffect(e6)

	-- 限制特殊召唤表示：只能以攻击表示进入场上
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_LIMIT_SPECIAL_SUMMON_POSITION)
	e7:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e7:SetRange(LOCATION_EXTRA)
	e7:SetTargetRange(1,0)
	e7:SetTarget(s.sumlimit)
	c:RegisterEffect(e7)
end

function s.sumlimit(e,c,sump,sumtype,sumpos,targetp)
	if c~=e:GetHandler() then return false end
	return bit.band(sumpos,POS_FACEUP_DEFENSE+POS_FACEDOWN_DEFENSE)~=0
end

-- 检查是否存在"共振壳"或"高能区域"
function s.supportfilter(c)
	return c:IsFaceup() and (c:IsCode(10000062) or c:IsCode(10000063))
end

function s.check_support_exist(tp)
	return Duel.IsExistingMatchingCard(s.supportfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
end

-- 召唤限制条件
function s.splimcon(e)
	local tp = e:GetHandlerPlayer()
	return s.check_support_exist(tp)
end

-- 特殊召唤条件：支援卡存在且有足够补给
function s.spcon(e,c)
	if c==nil then return true end
	local tp = c:GetControler()
	return s.check_support_exist(tp)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.CheckSupplyCost(tp, c:GetLevel())
end

-- 特殊召唤目标
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	if chk==0 then return s.spcon(e,c) end
	-- 在这里不执行操作，只是标记要支付的费用
	local cost = c:GetLevel()
	e:SetLabel(cost)
	return true
end

-- 特殊召唤操作
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local cost = e:GetLabel()
	Duel.PaySupplyCost(tp, cost)
end

-- 自毁条件：支援卡不存在
function s.descon(e)
	local tp = e:GetHandlerPlayer()
	return not s.check_support_exist(tp)
end

-- 休整阶段效果条件："共振壳"不存在且对方有单位

function s.draincon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
		and not Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,10000062)
		and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) and e:GetHandler():GetHp()<e:GetHandler():GetBaseHp()
end

-- 休整阶段效果目标：自动锁定对方最低生命值单位
function s.draintg(e,tp,eg,ep,ev,re,r,rp,chk)
	local target=s.find_lowest_hp_target(tp)
	if chk==0 then return target~=nil end
	local tg=Group.FromCards(target)
	Duel.SetTargetCard(tg)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,tg,1,0,0)
end

-- 寻找对方生命值最低的单位
function s.find_lowest_hp_target(tp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if g:GetCount()==0 then return nil end

	local lowest_hp
	local best
	local tc = g:GetFirst()
	while tc do
		local hp = tc:GetHp()
		if not lowest_hp or hp < lowest_hp or (hp==lowest_hp and s.is_better_target(tc,best)) then
			lowest_hp = hp
			best = tc
		end
		tc = g:GetNext()
	end
	return best
end

function s.is_better_target(c,reference)
	if reference==nil then return true end
	if c:GetControler()~=reference:GetControler() then
		return c:GetControler()<reference:GetControler()
	end
	if c:GetLocation()~=reference:GetLocation() then
		return c:GetLocation()<reference:GetLocation()
	end
	if c:GetSequence()~=reference:GetSequence() then
		return c:GetSequence()<reference:GetSequence()
	end
	return c:GetFieldID()<reference:GetFieldID()
end

-- 休整阶段操作：伤害和恢复
function s.drainop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	local target = Duel.GetFirstTarget()
	if target then
		if not target:IsRelateToEffect(e) then return end
		-- 计算伤害：原本生命值 - 当前生命值
		local original_hp = c:GetBaseHp()
		local current_hp = c:GetHp()
		local damage = original_hp - current_hp

		if damage > 0 then
			-- 对目标造成伤害
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_HP)
			e1:SetValue(-damage)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			target:RegisterEffect(e1)

			-- 恢复自身2的生命值
			local recover =2 
			if recover > 0 then
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_UPDATE_HP)
				e2:SetValue(recover)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e2)
			end
		end
	end
end

-- 被破坏时伤害条件
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) and c:IsPreviousLocation(LOCATION_MZONE)
end

-- 被破坏时伤害操作
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local damage = c:GetPreviousDefenseOnField()
	if damage > 0 then
		-- 对全场单位造成伤害（减少生命值），系统会自动处理生命值为0的摧毁
		local g = Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		local tc = g:GetFirst()
		while tc do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_HP)
			e1:SetValue(-damage)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			tc = g:GetNext()
		end
	end
end