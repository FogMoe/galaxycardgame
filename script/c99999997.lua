--集成测试：防御力增益消失验证
--演示影之诗式防御力管理机制的实际效果
local s, id = Import()
function s.initial(c)
	-- 测试效果：演示防御力增益和伤害的交互
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetOperation(s.demo_shadowverse_mechanics)
	c:RegisterEffect(e1)
end

-- 演示影之诗式防御力管理
function s.demo_shadowverse_mechanics(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	
	-- 步骤1：显示当前状态
	local current_def = c:GetDefense()
	local base_def = c:GetBaseDefense()
	Debug.Message("步骤1 - 当前状态: " .. current_def .. " DEF (基础: " .. base_def .. ")")
	
	-- 步骤2：模拟场地卡增益效果 (+1 防御)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_DEFENSE)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
	
	local boosted_def = c:GetDefense()
	Debug.Message("步骤2 - 场地增益后: " .. boosted_def .. " DEF (+1增益)")
	
	-- 步骤3：模拟受到1点伤害
	Galaxy.ApplyDamage(c, 1)
	local damaged_def = c:GetDefense()
	Debug.Message("步骤3 - 受到1点伤害后: " .. damaged_def .. " DEF")
	
	-- 步骤4：在回合结束时增益效果消失，测试是否存活
	-- (增益效果会在PHASE_END时自动重置)
	Debug.Message("步骤4 - 增益将在回合结束时消失，测试存活性...")
	Debug.Message("预期结果：怪兽应该存活(防御力≥1)而不是不合理死亡(防御力≤0)")
	Debug.Message("新机制：当增益消失时，当前生命值 = min(当前生命值, 新的最大生命值)")
end