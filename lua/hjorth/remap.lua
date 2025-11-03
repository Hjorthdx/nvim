vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
)

vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>");

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

-------------------
-- CUSTOM MACROS --
-------------------

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)

vim.fn.setreg("l", "yoconsole.log('" .. esc .. "pa: ', " .. esc .. "pa)" .. esc)
vim.api.nvim_create_user_command(
    'ReplaceInProject',
    function(opts)
        local line = vim.fn.getline('.')
        local parts = vim.split(line, ',')
        if #parts ~= 2 then
            vim.notify('Line must contain exactly one comma to split key/value', vim.log.levels.ERROR)
            return
        end
        local search_term = vim.fn.trim(parts[1])
        local replace_term = vim.fn.trim(parts[2])
        -- Store terms for later use
        vim.fn.setreg('s', search_term)
        vim.fn.setreg('r', replace_term)
        -- Launch Telescope search
        require('telescope.builtin').grep_string({ search = search_term })
        -- Provide instructions
        vim.notify(
            "In Telescope:\n" ..
            "1. Press <C-q> to send results to quickfix\n" ..
            "2. Then press <leader>ri to replace with confirmation",
            vim.log.levels.INFO,
            { timeout = 5000 }
        )
    end,
    {}
)

vim.keymap.set('n', '<leader>ra', function()
    local search = vim.fn.getreg('s')
    local replace = vim.fn.getreg('r')
    -- Replace all occurrences in all files from quickfix
    vim.cmd("cfdo %s/\\<" .. search .. "\\>/" .. replace .. "/ge | update")
    vim.notify("Replaced all occurrences of '" .. search .. "' with '" .. replace .. "'", vim.log.levels.INFO)
    vim.cmd("cclose")
end, { noremap = true, desc = "Replace all in quickfix files" })

vim.keymap.set('n', '<leader>rp', ':ReplaceInProject<CR>', { noremap = true })

vim.keymap.set('n', '<leader>rb', function()
    -- Get the current line
    local line = vim.fn.getline('.')

    -- Split and process
    local parts = vim.split(line, ',')
    if #parts ~= 2 then
        vim.notify('Line must contain exactly one comma', vim.log.levels.ERROR)
        return
    end

    local search_term = vim.fn.trim(parts[1])
    local replace_term = vim.fn.trim(parts[2])

    -- Store terms for use by the next step
    vim.g.current_search = search_term
    vim.g.current_replace = replace_term

    -- Use ripgrep and open quickfix
    local cmd = string.format("grep! '\\b%s\\b' .", search_term)
    vim.cmd(cmd)
    vim.cmd("copen")

    -- Notify the user what to do next
    vim.notify(
        "Found matches for '" .. search_term .. "'\n" ..
        "Press <leader>rc to confirm and replace with '" .. replace_term .. "'",
        vim.log.levels.INFO
    )
end, { noremap = true, desc = "Find occurrences of current line term" })

-- Add a companion mapping to perform the replacement after reviewing
vim.keymap.set('n', '<leader>rc', function()
    local search_term = vim.g.current_search
    local replace_term = vim.g.current_replace

    if not search_term or not replace_term then
        vim.notify("No replacement terms stored. Run <leader>rb first.", vim.log.levels.ERROR)
        return
    end

    -- Perform the replacement
    vim.cmd(string.format("cfdo %%s/\\<%s\\>/%s/ge | update", search_term, replace_term))
    vim.cmd("cclose")

    -- Move to next line in the original buffer
    vim.cmd("normal! j")

    vim.notify("Replaced '" .. search_term .. "' with '" .. replace_term .. "'", vim.log.levels.INFO)
end, { noremap = true, desc = "Confirm replace in quickfix files" })
