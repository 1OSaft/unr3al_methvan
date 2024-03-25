----------------------------------------------------------------

-- 1 out of 3 Progress updates gets a minigame
Config.ChangeMiniGame = 3

----------------------------------------------------------------

Config.DrugEffectLengh = 600000 --5min
Config.SmokeColor = 'orange' --orange, white or black

----------------------------------------------------------------

Config.SkillCheck = {
    StartingProd = {
        Enabled = true,
        Difficulty = {'easy', 'easy'},
        Key = {'e'} --You can add multiple with {'w', 'a', 's', 'd'}
    },

    Questions = {
        DisableAll = false, --if true, no Skillcheck will be done on questions

        --Diffuclty 0 is no Skillcheck
        Difficulty_1 = {
            Difficulty = {'easy', 'easy'},
            Key = {'e'} --You can add multiple with {'w', 'a', 's', 'd'}
        },
        Difficulty_2 = {
            Difficulty = {'medium', 'medium'},
            Key = {'e'} --You can add multiple with {'w', 'a', 's', 'd'}
        },


        Question_01 = {
            Enabled = true,
            DifficultyAnswer_1 = 1,
            DifficultyAnswer_3 = 2
        },

        Question_02 = {
            Enabled = true,
            DifficultyAnswer_1 = 1,
            DifficultyAnswer_3 = 1
        },

        Question_03 = {
            Enabled = true,
            DifficultyAnswer_2 = 1,
            DifficultyAnswer_3 = 1
        },

        Question_04 = {
            Enabled = true,
            DifficultyAnswer_2 = 1,
            DifficultyAnswer_3 = 2
        },

        Question_05 = {
            Enabled = true,
            DifficultyAnswer_1 = 1,
        },

        Question_06 = {
            Enabled = true,
            DifficultyAnswer_1 = 1,
            DifficultyAnswer_2 = 0,
        },

        Question_07 = {
            Enabled = true,
        },

        Question_08 = {
            Enabled = true,
            DifficultyAnswer_1 = 1,
        }
    }
}