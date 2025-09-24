--技术交易
local s, id = Import()
function s.initial(c)
	--陷阱卡，可以从手卡发动。这个回合每次对方把等级4以上的怪兽特殊召唤到场上时，自己抽2张卡。
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--手卡发动功能已由Galaxy全局规则提供
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.drcon1)
	e1:SetOperation(s.drop1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	--sp_summon effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.regcon)
	e2:SetOperation(s.regop)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_CHAIN_SOLVED)
	e3:SetCondition(s.drcon2)
	e3:SetOperation(s.drop2)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end
function s.filter(c,sp)
	return c:IsSummonPlayer(sp) and c:IsLevelAbove(4)
end
function s.drcon1(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.filter,1,nil,1-tp)
		and not Duel.IsChainSolving()
end
function s.drop1(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.filter,nil,1-tp)
	Duel.Draw(tp,ct*2,REASON_EFFECT)
end
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.filter,1,nil,1-tp)
		and Duel.IsChainSolving()
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.filter,nil,1-tp)
	Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,ct)
end
function s.drcon2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0
end
function s.drop2(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetFlagEffect(tp,id)
	Duel.ResetFlagEffect(tp,id)
	Duel.Draw(tp,ct*2,REASON_EFFECT)
end
