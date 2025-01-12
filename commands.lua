function RFP.CLOSE(idBinding, strCommand)
    print("--proxy close--")

    SWITCH_STATE = "closed"

    SwitchControl("turn_on")
end

function RFP.TOGGLE(idBinding, strCommand)
    print("--proxy toggle--")

    if SWITCH_STATE == "open" then
        RFP:CLOSE(strCommand)
    else
        RFP:OPEN(strCommand)
    end
end

function RFP.OPEN(idBinding, strCommand)
    print("--proxy open--")

    SWITCH_STATE = "open"

    SwitchControl("turn_off")
end

function EC.Turn_On(tParams)
    SwitchControl("turn_on")
end

function EC.Turn_Off(tParams)
    SwitchControl("turn_off")
end

function RFP.BUTTON_ACTION(idBinding, strCommand, tParams)
    if tParams.ACTION == "2" then
        if tParams.BUTTON_ID == "0" then
            RFP:CLOSE(strCommand)
        elseif tParams.BUTTON_ID == "1" then
            RFP:OPEN(strCommand)
        else
            RFP:TOGGLE(strCommand)
        end
    end
end

function RFP.DO_CLICK(idBinding, strCommand, tParams)
    local tParams = {
        ACTION = "2",
        BUTTON_ID = ""
    }

    if idBinding == 200 then
        tParams.BUTTON_ID = "0"
    elseif idBinding == 201 then
        tParams.BUTTON_ID = "1"
    elseif idBinding == 202 then
        tParams.BUTTON_ID = "2"
    end

    RFP:BUTTON_ACTION(strCommand, tParams)
end

function SwitchControl(service)
    local domain = "switch"
    if string.find(EntityID, "input_boolean.") then
        domain = "input_boolean"
    end

    local switchServiceCall = {
        domain = domain,
        service = service,

        service_data = {},

        target = {
            entity_id = EntityID
        }
    }

    local tParams = {
        JSON = JSON:encode(switchServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.RECEIEVE_STATE(idBinding, strCommand, tParams)
    local jsonData = JSON:decode(tParams.response)

    local stateData

    if jsonData ~= nil then
        stateData = jsonData
    end

    Parse(stateData)
end

function RFP.RECEIEVE_EVENT(idBinding, strCommand, tParams)
    local jsonData = JSON:decode(tParams.data)

    local eventData

    if jsonData ~= nil then
        eventData = jsonData["event"]["data"]["new_state"]
    end

    Parse(eventData)
end

function Parse(data)
    if data == nil then
        print("NO DATA")
        return
    end

    if data["entity_id"] ~= EntityID then
        return
    end

    local state = data["state"]

    if not Connected then
        Connected = true
    end

    if state ~= nil then
        if state == "on" then
            SWITCH_STATE = "closed"
            C4:SendToProxy(1, 'CLOSED', {}, "NOTIFY")
        elseif state == "off" then
            SWITCH_STATE = "open"
            C4:SendToProxy(1, 'OPENED', {}, "NOTIFY")
        end
    end
end
