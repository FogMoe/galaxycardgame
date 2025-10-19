
--[[
--==============================================
-- 暂时无用
--==============================================

--补给代价系统配置
Galaxy.USE_COST_SYSTEM = true
--Galaxy.SPELL_TRAP_COST = true   --魔法陷阱发动需要代价（暂时禁用）
Galaxy.SPELL_TRAP_COST = false  --魔法陷阱发动暂时不需要代价

--补给代价系统基础函数
Galaxy.DEFAULT_SUMMON_COST = 0   --怪兽召唤/特殊召唤默认代价（实际使用星级）
Galaxy.DEFAULT_ACTIVATE_COST = 0   --魔法/陷阱发动默认代价

--代价存储的Flag ID
Galaxy.SUMMON_COST_FLAG = 99990001  --召唤代价Flag
Galaxy.ACTIVATE_COST_FLAG = 99990002  --发动代价Flag

--获取卡片的召唤代价（从Flag读取，怪兽默认为星级）
function Galaxy.GetSummonCost(c)
	--检查卡片是否有自定义代价Flag
	if c:GetFlagEffect(Galaxy.SUMMON_COST_FLAG) > 0 then
		return c:GetFlagEffectLabel(Galaxy.SUMMON_COST_FLAG)
	end
	--怪兽卡默认代价为星级，其他卡片默认为0
	if c:IsType(TYPE_MONSTER) then
		return c:GetLevel()
	end
	return Galaxy.DEFAULT_SUMMON_COST
end

--获取卡片的发动代价（从Flag读取）
function Galaxy.GetActivateCost(c)
	--检查卡片是否有自定义代价Flag
	if c:GetFlagEffect(Galaxy.ACTIVATE_COST_FLAG) > 0 then
		return c:GetFlagEffectLabel(Galaxy.ACTIVATE_COST_FLAG)
	end
	--默认无代价
	return Galaxy.DEFAULT_ACTIVATE_COST
end

--为卡片设置召唤代价的便捷函数
function Galaxy.SetSummonCost(c, cost)
	--使用RegisterFlagEffect存储代价信息
	c:RegisterFlagEffect(Galaxy.SUMMON_COST_FLAG, 0, 0, 0, cost)
end

--为卡片设置发动代价的便捷函数
function Galaxy.SetActivateCost(c, cost)
	--使用RegisterFlagEffect存储代价信息
	c:RegisterFlagEffect(Galaxy.ACTIVATE_COST_FLAG, 0, 0, 0, cost)
end

--为魔法/陷阱卡添加发动代价效果（通用代价包装）
--注意：此功能已暂时禁用，魔法陷阱卡发动暂时不需要支付代价
function Galaxy.AddActivateCostToCard(c)
	if not Galaxy.USE_COST_SYSTEM or not Galaxy.SPELL_TRAP_COST then return end
	if not c or not (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) then return end

	--此函数现在主要用于标记卡片需要代价
	--实际代价处理通过Galaxy.WrapCost函数进行，在各卡片脚本中调用
	--使用方式: e1:SetCost(Galaxy.WrapCost(c, original_cost_function))
end

--通用的补给代价包装函数：将Galaxy补给代价与原始代价组合
function Galaxy.WrapCost(c, original_cost)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		local galaxy_cost = Galaxy.GetActivateCost and Galaxy.GetActivateCost(c) or 0

		if chk==0 then
			--检查Galaxy代价
			local galaxy_ok = true
			if galaxy_cost > 0 then
				galaxy_ok = Duel.CheckSupplyCost(tp, galaxy_cost) or false
			end
			--检查原始代价
			local original_ok = not original_cost or original_cost(e,tp,eg,ep,ev,re,r,rp,chk)
			return galaxy_ok and original_ok
		else
			--支付Galaxy代价
			if galaxy_cost > 0 then
				Duel.PaySupplyCost(tp, galaxy_cost)
			end
			--支付原始代价
			if original_cost then
				original_cost(e,tp,eg,ep,ev,re,r,rp,chk)
			end
		end
	end
end

--简化版本：无原始代价的包装函数
function Galaxy.SimpleCost(c)
	return Galaxy.WrapCost(c, nil)
end

--发动补给代价支付操作
function Galaxy.ActivateCostOperation(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	local cost = Galaxy.GetActivateCost(c)
	Duel.PaySupplyCost(tp, cost)
end
--]]