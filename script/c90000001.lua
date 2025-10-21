local s,id=Import()
function s.initial(c)
	--每回合限1次：消耗2补给，选择1个敌我单位，造成1点伤害
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(GALAXY_LOCATION_SUPPORT_ZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1)
	e1:SetCost(s.dmgcost)
	e1:SetTarget(s.dmgtg)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.dmgop)
	c:RegisterEffect(e1)
end
-- 激活条件：卡组中只有节肢动物单位
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- 获取卡组中所有单位卡
	local g=Duel.GetMatchingGroup(s.unitfilter,tp,LOCATION_DECK,0,nil)
	-- 如果没有单位卡，返回false
	if #g==0 then return false end
	-- 检查是否所有单位都是节肢动物类
	return not g:IsExists(s.nonarthropodfilter,1,nil)
end
-- 筛选单位卡
function s.unitfilter(c)
	return c:IsType(GALAXY_TYPE_UNIT)
end

-- 筛选非节肢动物类单位
function s.nonarthropodfilter(c)
	return not c:IsRace(GALAXY_CATEGORY_ARTHROPOD)
end

function s.dmgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

function s.dmgfilter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT)
end

function s.dmgtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and s.dmgfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.dmgfilter,tp,GALAXY_LOCATION_UNIT_ZONE,GALAXY_LOCATION_UNIT_ZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.dmgfilter,tp,GALAXY_LOCATION_UNIT_ZONE,GALAXY_LOCATION_UNIT_ZONE,1,1,nil)
end

function s.dmgop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then
		return
	end
	Duel.AddHp(tc,-1,REASON_EFFECT)
end
