Config, Locales = {}, {}
----------------------------------------------------------------
Config.Locale = 'en'
Config.checkForUpdates = true
Config.Debug = true
----------------------------------------------------------------

Config.StartProduction = {
    Item = {
        Enabled = true,
        ItemName = 'methlab',
        ConsumeOnStart = false
    },
    Key = {
        Enabled = true,
        StartKey = 'G'
    }
}

Config.Inventory = {
    ForceAdd = false, --Should the meth alsways be added, including when the player cant carry it?

    --Only works with ox_inventory
    oxSplit = true, -- if true, the player only receives the amount he can carry
}

-- Time between every % update
Config.PauseTime = 4000

-- % every update gets added
Config.Progress = {
    Min = 5,
    Max = 10
}

Config.Police                     = 'police'            -- Your Police society name
Config.PoliceCount                = 0

Config.Cam = true --Enable the new camera system

Config.LogType = 'disabled' --Valid options are 'ox_lib', 'discord' or 'disabled'

Config.Items = {
    Methlab = 'methlab',

    EnableDifferentMethTypes = true, -- If you disabble the different meth types the input dialog disappeares and it takes the values out of the Easy type

    ["Easy"] = {
        Label = "Easy",
        Ingredients = {
            ["acetone"] = 1,
            ["lithium"] = 1,
        },
        Meth = {
            ItemName = 'meth',
            Chance = { -- At the End a random amount of Meth gets added to the quantity received by questions
                Min = -5,
                Max = 5
            },
        }
    },
    ["Medium"] = {
        Label = "Medium",
        Ingredients = {
            ["acetone"] = 8,
            ["lithium"] = 4,
        },
        Meth = {
            ItemName = 'meth',
            Chance = { -- At the End a random amount of Meth gets added to the quantity received by questions
                Min = 0,
                Max = 12
            },
        }
    },
    ["Hard"] = {
        Label = "Hard",
        Ingredients = {
            ["acetone"] = 12,
            ["lithium"] = 8,
        },
        Meth = {
            ItemName = 'meth',
            Chance = { -- At the End a random amount of Meth gets added to the quantity received by questions
                Min = 7,
                Max = 20
            },
        }
    }
}


Config.Noti = {
    --Notifications types:
    success = 'success',
    error = 'error',
    info = 'inform',

    --Notification time:
    time = 5000,
}

function notifications(notitype, message, time)
    --Change this trigger for your notification system keeping the variables
    lib.notify({
        title = 'Meth Van',
        description = message,
        type = notitype,
        duration = time
    })
end