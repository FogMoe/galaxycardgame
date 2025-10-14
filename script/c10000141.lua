--星际漫游者
--部署时，选择1项获得效果（
--数值：+3/+3。
--技能：致命，隐身。
--均衡：获得3点补给。
--)

local s,id=Import()

function s.initial(c)
	-- 部署时选择效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)
end

-- 操作：让玩家选择效果
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() or not c:IsLocation(LOCATION_MZONE) then return end

	-- 让玩家选择3个选项之一
	local sel=Duel.SelectOption(tp,
		aux.Stringid(id,1),  -- 选项1：数值+3/+3
		aux.Stringid(id,2),  -- 选项2：技能（致命，隐身）
		aux.Stringid(id,3))  -- 选项3：均衡（获得3点补给）

	if sel==0 then
		-- 选项1：数值+3/+3
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(3)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)

		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_HP)
		e2:SetValue(3)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)

		-- 客户端提示
		local e3=Effect.CreateEffect(c)
		e3:SetDescription(aux.Stringid(id,1))
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e3)

	elseif sel==1 then
		-- 选项2：技能（致命，隐身）
		-- 致命效果
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LETHAL)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)

		-- 隐身效果
		if not c:IsHasEffect(EFFECT_STEALTH) then
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_STEALTH)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e2)

			-- 隐身客户端提示
			if not c:IsHasEffect(EFFECT_STEALTH_HINT) then
				local e3=Effect.CreateEffect(c)
				e3:SetDescription(aux.Stringid(10000077,3)) -- 隐身显示提示文本
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_STEALTH_HINT) -- 隐身显示标识码
				e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
				e3:SetRange(GALAXY_LOCATION_UNIT_ZONE)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
				c:RegisterEffect(e3)
			end
		end

		-- 致命客户端提示
		local e4=Effect.CreateEffect(c)
		e4:SetDescription(aux.Stringid(id,0))
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
		c:RegisterEffect(e4)

	elseif sel==2 then
		-- 选项3：均衡（获得3点补给）
		Duel.AddSupply(tp,3)

		-- 客户端提示
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,3))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
