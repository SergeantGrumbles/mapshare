local writingImplements = {
    { item = "Pen", },
    { item = "Pencil", },
    { item = "RedPen", },
    { item = "BluePen", }
};

local getWritingImplementOrDefault = function(availableWritingImplements, writingImplementName)
    for _, info in ipairs(availableWritingImplements) do
        print(info.item)
        if info.item == writingImplementName then
            return writingImplementName
        end
    end
    return availableWritingImplements[0]
end

local shouldReturnItem = function()
    local availableWritingImplements = {}

    for _, info in ipairs(writingImplements) do
        table.insert(availableWritingImplements, info)
    end



    local item = getWritingImplementOrDefault(availableWritingImplements, nil)
    print(item)
end

shouldReturnItem();
