--支援卡：消耗2点补给，为所有友方机械单位恢复3点生命值。如果目标已满血，改为获得+2生命值。
local s,id=Import()

function s.initial(c)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil,tp)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckSupplyCost(tp,2) end
    Duel.PaySupplyCost(tp,2)
end

function s.filter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsType(GALAXY_TYPE_UNIT) and c:IsRace(RACE_MACHINE)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil,tp)
    for tc in aux.Next(g) do
        local max_hp=tc:GetMaxHp()
        local current_hp=tc:GetHp()
        if current_hp<max_hp then
            Duel.AddHp(tc,3,REASON_EFFECT)
        else
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_DEFENSE)
            e1:SetValue(2)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
        end
    end
end
