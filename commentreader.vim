python << EOF
import vim

class segment():
    def __init__(self, fd, **option):
        self.length   = option['length']
        self.width    = option['width']
        self.lcom     = option['lcom']
        self.filler   = option['filler']
        self.rcom     = option['rcom']
        self.position = option['position']

        self.content = []
        line_loaded = 0
        while line_loaded <= self.length:
            line = fd.readline().decode('utf-8')
            # if reached the eof
            if not line: break
            # TODO
            # 这样的话把空行也全部删掉了
            # 还有空格是半角的，但是却占一个字数
            line = line.rstrip('\r\n')
            p = 0
            while p < len(line):
                self.content.append(line[p:p+self.width])
                line_loaded += 1
                p += self.width

    def commentize(self):
        output = self.lcom + self.filler * self.width + "\\n"
        for line in self.content:
            output += "{0} {1}\\n".format(self.filler, line.encode('utf-8'))
        output += self.filler * self.width + self.rcom + "\\n"
        return output

class page():
    def __init__(self, fd, **option):
        self.length        = option['length']
        self.width         = option['width']
        self.defs          = option['defs']
        self.current_block = 0
        self.segments      = []

        self.anchors = []
        (o_line, o_col) = (vim.eval("line('.')"), vim.eval("col('.')"))
        vim.command("call cursor('1', '1')")
        while 1:
            anchor = int(vim.eval("search('{0}', 'W')".format(self.defs)))
            if anchor == 0: break
            self.anchors.append(anchor)
        # TODO
        # 如果不存在锚点，再做错误处理

        # recover the cursor position
        vim.command("call cursor('{0}', '{1}')".format(o_line, o_col))

        for a in range(len(self.anchors)):
            if a == 0:
                option['position'] = self.anchors[a]
            else:
                option['position'] += self.anchors[a] - self.anchors[a-1] + len(self.segments[-1].content) + 2
            new_segment = segment(fd, **option)
            if not new_segment.content: break

            self.segments.append(new_segment)

    def render(self):
        # segments may less than anchors
        for a in range(len(self.anchors)):
            if a >= len(self.segments): break

            content = self.segments[-a-1].commentize()
            # escape '"' as a string
            for char in '"':
                content = content.replace(char, '\\'+char)

            # insert segments in descending order
            # otherwise the line numbers will mess
            anchor = self.anchors[-a-1]

            command = 'silent! {0}put! ="{1}"'.format(anchor, content)
            # escape '|' and '"' as argument for 'put' command
            for char in '|"':
                command = command.replace(char, '\\'+char)

            # let 'modified' intact
            o_modified = vim.eval('&modified')
            vim.command(command)
            vim.command('let &modified={0}'.format(o_modified))

            # set cursor to first block
            self.current_block = 0
            vim.command("call cursor('{0}', '1')".format(self.segments[self.current_block].position))

    def clear(self):
        # segments may less than anchors
        for a in range(len(self.anchors)):
            if a >= len(self.segments): break
            anchor = self.anchors[a]
            segment = self.segments[a]
            crange = "{0},{1}".format(anchor, anchor+len(segment.content)+1)

            command = "silent! {0}delete _".format(crange)

            # let 'modified' intact
            o_modified = vim.eval('&modified')
            vim.command(command)
            vim.command('let &modified={0}'.format(o_modified))

    def nextBlock(self):
        if self.current_block < len(self.segments)-1:
            self.current_block += 1
        else:
            self.current_block = self.current_block
        vim.command("call cursor('{0}', '1')".format(self.segments[self.current_block].position))

    def preBlock(self):
        if self.current_block > 0:
            self.current_block -= 1
        else:
            self.current_block = self.current_block
        vim.command("call cursor('{0}', '1')".format(self.segments[self.current_block].position))

class book():
    def __init__(self, path, **option):
        self.fd           = open(path, 'r')
        self.pages        = []
        self.current_page = -1
        self.on_show      = 0
        self.length       = option['length']
        self.width        = option['width']

        # define commenters
        filetype = vim.eval("&filetype")
        if filetype in langdict:
            self.lcom   = langdict[filetype]['lcom']
            self.filler = langdict[filetype]['filler']
            self.rcom   = langdict[filetype]['rcom']
        else:
            self.lcom = vim.eval(r"substitute(&commentstring, '\([^ \t]*\)\s*%s.*', '\1', '')")
            # TODO
            # 研究一下填充物应该怎么确定
            self.filler = vim.eval(r"substitute(&commentstring, '\([^ \t]*\)\s*%s.*', '\1', '')")
            self.rcom = vim.eval(r"substitute(&commentstring, '.*%s\s*\(.*\)', '\1', 'g')")

        # define statement
        self.defs = langdict[filetype]['defs']

    def nextPage(self):
        option = {
                'length' : self.length,
                'width'  : self.width,
                'lcom'   : self.lcom,
                'filler' : self.filler,
                'rcom'   : self.rcom,
                'defs'   : self.defs,
                }
        new_page = page(self.fd, **option)

        # if reached the end
        if not new_page.segments:
            return self.pages[self.current_page]

        self.pages.append(new_page)
        self.current_page += 1
        return self.pages[self.current_page]

    def prePage(self):
        # TODO 
        # 对于当前页还是-1时调用prePage还需要额外处理错误
        if self.current_page == -1:
            return
        elif self.current_page == 0:
            return self.pages[self.current_page]

        self.current_page -= 1
        return self.pages[self.current_page]

    def render(self):
        if self.on_show: return
        page = self.pages[self.current_page]
        page.render()
        self.on_show = 1

    def clear(self):
        if not self.on_show: return
        page = self.pages[self.current_page]
        page.clear()
        self.on_show = 0


langdict = {
            'python':  { 'lcom':  '#', 'filler':   '#', 'rcom':   '#', 'defs':   r'^def' },
            'perl':    { 'lcom':  '#', 'filler':   '#', 'rcom':   '#', 'defs':   r'^sub' },
            'vim':     { 'lcom':  '"', 'filler':   '"', 'rcom':   '"', 'defs':   r'^function' },
            'c':       { 'lcom':  '/*', 'filler':  '*', 'rcom':   '*/', 'defs':  r''},
            'cpp':     { 'lcom':  '//', 'filler':  '//', 'rcom':  '//', 'defs':  r''},
           }
EOF

if !exists('g:creader_chars_per_line')
    let g:creader_chars_per_line = 20
endif
if !exists('g:creader_lines_per_block')
    let g:creader_lines_per_block = 5
endif

function! s:CRopen(path)
python << EOF
path = vim.eval('a:path')
option = {
        'length' : int(vim.eval('g:creader_lines_per_block')),
        'width'  : int(vim.eval('g:creader_chars_per_line')),
        }
myBook = book(path, **option)
EOF
endfunction

function! s:CRnextpage()
python << EOF
myBook.clear()
myBook.nextPage()
myBook.render()
EOF
endfunction

function! s:CRprepage()
python << EOF
myBook.clear()
myBook.prePage()
myBook.render()
EOF
endfunction

function! s:CRclear()
python << EOF
myBook.clear()
EOF
endfunction

function! s:CRnextblock()
python << EOF
myBook.pages[myBook.current_page].nextBlock()
EOF
endfunction

function! s:CRpreblock()
python << EOF
myBook.pages[myBook.current_page].preBlock()
EOF
endfunction

command! -nargs=1 -complete=file CRopen      call s:CRopen('<args>')
command! -nargs=0                CRnextpage  call s:CRnextpage()
command! -nargs=0                CRprepage   call s:CRprepage()
command! -nargs=0                CRclear     call s:CRclear()
command! -nargs=0                CRnextblock call s:CRnextblock()
command! -nargs=0                CRpreblock  call s:CRpreblock()

nnoremap <silent> <leader>d :CRnextpage<CR>
nnoremap <silent> <leader>a :CRprepage<CR>
nnoremap <silent> <leader>w :CRpreblock<CR>
nnoremap <silent> <leader>s :CRnextblock<CR>
