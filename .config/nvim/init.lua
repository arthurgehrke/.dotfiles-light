vim.opt.clipboard = { 'unnamedplus' }
vim.o.ruler = true
vim.opt.cursorline = true
vim.opt.undolevels = 10000
vim.opt.history = 1000
vim.opt.wrap = false

vim.keymap.set('i', 'jj', '<Esc>', options)
vim.keymap.set('i', 'jk', '<Esc>', options)

vim.keymap.set('n', 'sh', '<C-w>h', options)
vim.keymap.set('n', 'sj', '<C-w>j', options)
vim.keymap.set('n', 'sk', '<C-w>k', options)
vim.keymap.set('n', 'sl', '<C-w>l', options)

vim.keymap.set('v', '<', '<gv', options)
vim.keymap.set('v', '>', '>gv', options)


