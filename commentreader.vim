if has("python")
python << EOF
import vim

class segment():
    def __init__(self, fd, **option):
        self.length = option['length']
        self.width = option['width']
        self.commenter = option['commenter']

        self.content = []
        line_loaded = 0
        while line_loaded <= self.length:
            line = fd.readline().decode('utf-8')
            # if reached the eof
            if not line: break
            # TODO
            # 这样的话把空行也全部删掉了
            # 还有文本中存在引号的问题必须解决
            line = line.rstrip('\r\n')
            p = 0
            while p < len(line):
                self.content.append(line[p:p+self.width])
                line_loaded += 1
                p += self.width

    def commentize(self):
        output = self.commenter * self.width + "\\n"
        for line in self.content:
            output += "{0} {1}\\n".format(self.commenter, line.encode('utf-8'))
        output += self.commenter * self.width + "\\n"
        return output

class page():
    def __init__(self, fd, **option):
        self.length = option['length']
        self.width = option['width']
        self.segments = []

        # TODO
        # anchor需要被排序
        self.anchors = [2, 6, 11]

        for a in range(len(self.anchors)):
            new_segment = segment(fd, **option)
            if not new_segment.content: break
            self.segments.append(new_segment)

    def make(self):
        # segments may less than anchors
        for a in range(len(self.anchors)):
            if a >= len(self.segments): break
            content = self.segments[-a-1].commentize()
            # insert segments in descending order
            # otherwise the line numbers will mess
            anchor = self.anchors[-a-1]
            command = 'silent! {0}put! =\\"{1}\\"'.format(anchor, content)
            vim.command(command)

    def clear(self):
        # segments may less than anchors
        for a in range(len(self.anchors)):
            if a >= len(self.segments): break
            anchor = self.anchors[a]
            segment = self.segments[a]
            crange = "{0},{1}".format(anchor, anchor+len(segment.content)+1)

            command = "silent! {0}delete _".format(crange)
            vim.command(command)

class book():
    def __init__(self, path, **option):
        self.fd = open(path, 'r')
        self.pages = []
        self.current_page = -1
        self.on_show = 0
        self.length = option['length']
        self.width = option['width']

        # TODO
        # self.commenter = vim.eval(r"substitute(&commentstring, '\([^ \t]*\)\s*%s.*', '\1', '')")
        self.commenter = "#"

    def nextPage(self):
        option = {
                'length'    : self.length,
                'width'     : self.width,
                'commenter' : self.commenter,
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
        page.make()
        self.on_show = 1

    def clear(self):
        if not self.on_show: return
        page = self.pages[self.current_page]
        page.clear()
        self.on_show = 0
EOF
endif

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

command! -nargs=1 -complete=file CRopen     call s:CRopen('<args>')
command! -nargs=0                CRnextpage call s:CRnextpage()
command! -nargs=0                CRprepage  call s:CRprepage()
command! -nargs=0                CRclear    call s:CRclear()
