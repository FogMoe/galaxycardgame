--：离场送入弃牌区时，对全场所有非机械单位造成 4 点伤害。
local s,id=Import()

function s.initial(c)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DEFCHANGE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_TO_GRAVE)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.dmgcon)
    e1:SetOperation(s.dmgop)
    c:RegisterEffect(e1)
end

function s.dmgcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

function s.dmgop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,GALAXY_LOCATION_UNIT_ZONE,nil)
    for tc in aux.Next(g) do
        Duel.AddHp(tc,-4,REASON_EFFECT)
    end
end

function s.filter(c)
    return c:IsFaceup() and not c:IsRace(RACE_MACHINE)
end
