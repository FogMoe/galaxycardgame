--战斗工蜂
--闪击。护盾。
--部署时，吸收敌方4点影响力。
--在场时，对方场上所有单位获得效果（保护）。

local s,id=Import()

function s.initial(c)
	-- 效果1：闪击
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_RUSH_R)
	c:RegisterEffect(e1)

	-- 效果2：护盾
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SHIELD)
	c:RegisterEffect(e2)

	-- 效果3：部署时，吸收敌方4点影响力
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DAMAGE+CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetOperation(s.drainop)
	c:RegisterEffect(e3)

	-- 效果4：在场时，对方场上所有单位获得保护效果
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_PROTECT)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(0,LOCATION_MZONE)
	e4:SetTarget(s.protecttg)
	c:RegisterEffect(e4)

	-- -- 效果5：创建保护提示效果（用于授予）
	-- local e5=Effect.CreateEffect(c)
	-- e5:SetDescription(aux.Stringid(id,1))
	-- e5:SetType(EFFECT_TYPE_SINGLE)
	-- e5:SetCode(id)  -- 使用卡片ID作为效果码
	-- e5:SetProperty(EFFECT_FLAG_CLIENT_HINT)

	-- -- 效果6：将保护提示授予给对方场上所有单位
	-- local e6=Effect.CreateEffect(c)
	-- e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	-- e6:SetRange(LOCATION_MZONE)
	-- e6:SetTargetRange(0,LOCATION_MZONE)
	-- e6:SetTarget(s.protecttg)
	-- e6:SetLabelObject(e5)
	-- c:RegisterEffect(e6)
end

-- 效果3的操作：吸收敌方4点影响力
function s.drainop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		-- 对方失去4点影响力
		Duel.Damage(1-tp,4,REASON_EFFECT)
		-- 自己获得4点影响力
		Duel.Recover(tp,4,REASON_EFFECT)
	end
end

-- 效果4和6的目标：对方场上所有表侧表示的单位
function s.protecttg(e,c)
	return c:IsFaceup()
end
