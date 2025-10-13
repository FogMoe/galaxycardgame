--齐心协力机械 团结 弗兰得
--部署时，根据你场上其他机械单位的数量，获得追加效果（
--1个：抽1张卡。
--2个：闪击（RUSH_R）。
--3个：保护，护盾。
--4个：使自身和其他友方机械单位获得+1/+1。
--）可以叠加获得

local s,id=Import()

function s.initial(c)
	-- 部署时触发效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-- 筛选其他机械单位
function s.filter(c)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end

	-- 计算场上其他机械单位数量
	local ct=Duel.GetMatchingGroupCount(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,c)

	-- 1个或以上：抽1张卡
	if ct>=1 then
		Duel.Draw(tp,1,REASON_EFFECT)
	end

	-- 2个或以上：获得闪击（RUSH_R）
	if ct>=2 then
		-- 闪击效果
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_RUSH_R)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)

		-- 闪击提示
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
		c:RegisterEffect(e2)
	end

	-- 3个或以上：获得保护和护盾
	if ct>=3 then
		-- 保护（嘲讽）效果
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_PROTECT)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e3)

		-- 保护提示
		local e4=Effect.CreateEffect(c)
		e4:SetDescription(aux.Stringid(id,2))
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e4:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
		c:RegisterEffect(e4)

		-- 护盾效果
		local e5=Effect.CreateEffect(c)
		e5:SetType(EFFECT_TYPE_SINGLE)
		e5:SetCode(EFFECT_SHIELD)
		e5:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e5)

		-- 护盾提示
		local e6=Effect.CreateEffect(c)
		e6:SetDescription(aux.Stringid(10000077,2,))
		e6:SetType(EFFECT_TYPE_SINGLE)
		e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e6:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		e6:SetCode(EFFECT_SHIELD_HINT)
		e6:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
		c:RegisterEffect(e6)
	end

	-- 4个或以上：自己和其他友方机械单位获得+1/+1
	if ct>=4 then
		-- 获取所有友方机械单位（包括自己）
		local g=Duel.GetMatchingGroup(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
		if #g>0 then
			for tc in aux.Next(g) do
				-- 增加攻击力+1
				local e7=Effect.CreateEffect(c)
				e7:SetType(EFFECT_TYPE_SINGLE)
				e7:SetCode(EFFECT_UPDATE_ATTACK)
				e7:SetValue(1)
				e7:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e7)

				-- 增加最大HP+1
				local e8=Effect.CreateEffect(c)
				e8:SetType(EFFECT_TYPE_SINGLE)
				e8:SetCode(EFFECT_UPDATE_HP)
				e8:SetValue(1)
				e8:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e8)
			end
		end
	end
end
