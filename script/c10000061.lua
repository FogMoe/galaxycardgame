--极光水母
--1"共振壳"不存在于场上时，1回合1次，消耗3个高能指示物将一个敌方单位变为己方单位，然后使其效果无效。
--2被破坏时对全场单位造成这张卡剩余生命值的伤害。
--3当场上存在"共振壳"或"高能区域"时才可以被召唤。
--4当场上不存在"共振壳"或"高能区域"时破坏
local s, id = Import()
function s.initial(c)
	-- 3.召唤条件：当场上存在"共振壳"或"高能区域"时才可以被召唤
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

	-- 限制特殊召唤表示：只能以攻击表示进入场上
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_LIMIT_SPECIAL_SUMMON_POSITION)
	e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e6:SetRange(LOCATION_EXTRA)
	e6:SetTargetRange(1,0)
	e6:SetTarget(s.sumlimit)
	c:RegisterEffect(e6)

	-- 4.自毁条件：当场上不存在"共振壳"或"高能区域"时破坏
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_SELF_DESTROY)
	e3:SetCondition(s.descon)
	c:RegisterEffect(e3)

	-- 1.控制权获取效果："共振壳"不存在时，消耗高能指示物控制敌方单位并无效化
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.ctlcon)
	e4:SetCost(s.ctlcost)
	e4:SetTarget(s.ctltg)
	e4:SetOperation(s.ctlop)
	c:RegisterEffect(e4)

	-- 2.被破坏时对全场单位造成伤害
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_DAMAGE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_DESTROYED)
	e5:SetCondition(s.damcon)
	e5:SetOperation(s.damop)
	c:RegisterEffect(e5)
end

-- 检查是否存在"共振壳"或"高能区域"
function s.supportfilter(c)
	return c:IsFaceup() and (c:IsCode(10000062) or c:IsCode(10000063))
end

function s.check_support_exist(tp)
	return Duel.IsExistingMatchingCard(s.supportfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
end

function s.sumlimit(e,c,sump,sumtype,sumpos,targetp)
	if c~=e:GetHandler() then return false end
	return bit.band(sumpos,POS_FACEUP_DEFENSE+POS_FACEDOWN_DEFENSE)~=0
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

-- 控制权效果条件："共振壳"不存在
function s.ctlcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,10000062)
end

-- 控制权效果消耗：高能指示物
function s.ctlcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 使用标准API检查场上是否有足够的高能计数器
		return Duel.IsCanRemoveCounter(tp,1,0,0x1042,3,REASON_COST)
	end
	-- 消耗3个高能计数器
	Duel.RemoveCounter(tp,1,0,0x1042,3,REASON_COST)
end

-- 控制权目标
function s.ctltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsControlerCanBeChanged() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

-- 控制权操作
function s.ctlop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		if Duel.GetControl(tc,tp) then
			-- 使其效果无效
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
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
		-- 对全场单位造成伤害（减少生命值）
		local g = Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		local tc = g:GetFirst()
		while tc do
			-- 减少生命值，系统会自动处理生命值为0的摧毁
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_DEFENSE)
			e1:SetValue(-damage)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			tc = g:GetNext()
		end
	end
end