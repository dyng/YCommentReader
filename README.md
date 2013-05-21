CommentReader
=============

Read your favorite novel in Vim as comment ( Don't let your boss know :P )

Requirements
============

- Vim 7.3+
- Python support for Vim

Installation
=============

Just drop all files in `plugin/` to `$HOME/.vim/plugin/` directory and enjoy!

Although I recommend using [vundle](https://github.com/gmarik/vundle/) or [pathogen](https://github.com/tpope/vim-pathogen/) to manage your vim plugins.

Usage and Configuration
=============

At first you should open novel with `:CRopen path/to/your/novel`, note that the novel file need to be `plain text` with encoding `UTF-8`, then you can try `:CRnextpage` and `:CRprepage` to page, `:CRnextblock` and `:CRpreblock` to move around among comment blocks where your novel's content is in. Also, there are some handy keymaps for it by default.

Commands
-------------
- *CRopen*:      open novel file and initiate.
- *CRnextpage*:  load next page and render.
- *CRprepage*:   back to the previous page.
- *CRnextblock*: jump to the next comment block.
- *CRprepage*:   jump to the previous comment block.
- *Crclear*:     Clear all 'novel' blocks.

Maps
-------------
- *&lt;leader>d*: next page
- *&lt;leader>a*: previous page
- *&lt;leader>s*: next comment block
- *&lt;leader>w*: previous comment block

all above are in normal mode, and by default the `<leader>` is `\`

Configs
-------------
- *g:creader_chars_per_line*:  the character numbers per line.
- *g:creader_lines_per_block*: the line numbers in an individual comment block.
