--引力连锁器
--强化支援：消耗4点补给。装备任意友方单位；当装备单位与敌军战斗时，随机对另一个敌方单位造成等同装备单位攻击力的伤害。
local s,id=Import()

function s.initial(c)
    -- 启动装备
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_EQUIP)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- 装备限制：任意单位
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EQUIP_LIMIT)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetValue(s.eqlimit)
    c:RegisterEffect(e2)

    -- 战斗后随机对其他敌军造成伤害
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_BATTLE_CONFIRM)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCondition(s.dmgcon)
    e3:SetOperation(s.dmgop)
    c:RegisterEffect(e3)
end

--消耗4点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckSupplyCost(tp,4) end
    Duel.PaySupplyCost(tp,4)
end

function s.filter(c)
    return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and chkc:IsControler(tp) and s.filter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
    Duel.SelectTarget(tp,s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
    if Duel.Equip(tp,c,tc,false) then
        -- 客户端提示
        local hint=Effect.CreateEffect(c)
        hint:SetDescription(aux.Stringid(id,1))
        hint:SetType(EFFECT_TYPE_SINGLE)
        hint:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
        hint:SetRange(GALAXY_LOCATION_UNIT_ZONE)
        hint:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(hint,true)
    else
        Duel.SendtoGrave(c,REASON_EFFECT)
    end
end

function s.eqlimit(e,c)
    return c:IsType(GALAXY_TYPE_UNIT)
end

function s.dmgcon(e,tp,eg,ep,ev,re,r,rp)
    local ec=e:GetHandler():GetEquipTarget()
    if not ec or not ec:IsFaceup() then return false end
    e:SetLabelObject(nil)
    local at=Duel.GetAttacker()
    local de=Duel.GetAttackTarget()
    if not at or not de then return false end
    if at==ec and de:IsControler(1-tp) then
        e:SetLabelObject(de)
        return true
    end
    if de==ec and at:IsControler(1-tp) then
        e:SetLabelObject(at)
        return true
    end
    return false
end

function s.dmgop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ec=c:GetEquipTarget()
    if not ec or not ec:IsFaceup() then return end
    local opp=e:GetLabelObject()
    if opp and opp:IsRelateToBattle() then
        -- nothing
    else
        opp=nil
    end
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
    if opp then g:RemoveCard(opp) end
    if g:GetCount()==0 then return end
    local atk=ec:GetAttack()
    if atk<=0 then return end
    Duel.Hint(HINT_CARD,0,id)
    local sg=g:RandomSelect(tp,1)
    local tc=sg:GetFirst()
    if not tc then return end
    Duel.AddHp(tc,-atk,REASON_EFFECT)
    e:SetLabelObject(nil)
end
