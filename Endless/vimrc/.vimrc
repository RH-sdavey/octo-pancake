" Vim config
" Zdenek kraus
"
" Wed Mar 10 15:51:41 CET 2010
"


"  1 important
"  2 moving around, searching and patterns
"  3 tags
"  4 displaying text
"  5 syntax, highlighting and spelling
"  6 multiple windows
"  7 multiple tab pages
"  8 terminal
"  9 using the mouse
" 10 printing
" 11 messages and info
" 12 selecting text
" 13 editing text
" 14 tabs and indenting
" 15 folding
" 16 diff mode
" 17 mapping
" 18 reading and writing files
" 19 the swap file
" 20 command line editing
" 21 executing external commands
" 22 running make and jumping to errors
" 23 language specific
" 24 multi-byte characters
" 25 various


" 1 important

" compatible    behave very Vi compatible (not advisable)
set nocp

"  2 moving around, searching and patterns

" startofline   many jump commands move the cursor to the first non-blank
"       character of a line
set sol
" incsearch     show match for partly typed search command
set is
"
"  3 tags

"  4 displaying text
"
" scroll        number of lines to scroll for CTRL-U and CTRL-D
"       (local to window)
"       set scr=13
" scrolloff     number of screen lines to show around the cursor
set so=5
" wrap  long lines wrap
set nowrap
" linebreak     wrap long lines at a character in 'breakat'
"       (local to window)
set lbr
" showbreak     string to put before wrapped screen lines
set sbr=+++
" list  show <Tab> as ^I and end-of-line as $
"       (local to window)
set list
" number        show the line number for each line
"       (local to window)
set nu

"fillchars	characters to use for the status line, folds and filler lines
 	set fcs=vert:\|,fold:=

"  5 syntax, highlighting and spelling

syntax on
" background    "dark" or "light"; the background color brightness
set bg=dark
" hlsearch      highlight all matches for the last used search pattern
set hls
" spell highlight spelling mistakes
"       (local to window)
setlocal nospell
" spelllang     list of accepted languages
"       (local to buffer)
set spl=en,cs
" spellfile     file that "zg" adds good words to
"       (local to buffer)
set spf=$HOME/.vim/$USER.utf8.add

"  6 multiple windows

" laststatus    0, 1 or 2; when to use a status line for the last window
set ls=2
" statusline    alternate format to be used for a status line
set statusline=%1*%n:%*%2*\ %<%f\ %y%m%3*%r%*%2*%=[%b,0x%B]\ \ %l,%c\ \ %P%*
" hidden        don't unload a buffer when no longer shown in a window
set hid
" splitbelow    a new window is put below the current one
set sb
" splitright    a new window is put right of the current one
set spr

"  7 multiple tab pages

" showtabline   0, 1 or 2; when to use a tab pages line
set stal=2

"  8 terminal

"  9 using the mouse

" mouse list of flags for using the mouse
set mouse=

" 10 printing

" 11 messages and info

" showcmd       show (partial) command keys in the status line
set sc
" showmode      display the current mode in the status line
set smd
" more  pause listings when the screen is full
set more
" helplang      list of preferred languages for finding help
set hlg=en

" 12 selecting text

" clipboard     "unnamed" to use the * register like unnamed register
"       "autoselect" to always put selected text on the clipboard
set clipboard=unnamed

" 13 editing text

set formatoptions=rqlj

" undolevels    maximum number of changes that can be undone
set ul=1000
" textwidth     line length above which to break a line
"       (local to buffer)
set tw=0
" wrapmargin    margin from the right in which to break a line
"       (local to buffer)
set wm=2
" dictionary    list of dictionary files for keyword completion
"       (global or local to buffer)
set dict+=/usr/share/dict/words
" showmatch     When inserting a bracket, briefly jump to its match
set nosm
" matchtime     tenth of a second to show a match for 'showmatch'
set mat=5

" 14 tabs and indenting

" tabstop       number of spaces a <Tab> in the text stands for
"       (local to buffer)
set tabstop=4
" shiftwidth    number of spaces used for each step of (auto)indent
"       (local to buffer)
set shiftwidth=4
" shiftround    round to 'shiftwidth' for "<<" and ">>"
set shiftround
" expandtab     expand <Tab> to spaces in Insert mode
"       (local to buffer)
set expandtab
" softtabstop
set softtabstop=4
" autoindent    automatically set the indent of a new line TODO
"       (local to buffer)
"       set ai  noai
" smartindent   do clever autoindenting
"       (local to buffer)
set nosi
" cindent       enable specific indenting for C code TODO
"       (local to buffer)
"set cin
" cinoptions    options for C-indenting TODO
"       (local to buffer)
set cino=l1,g0,t0,(0
    " -- l1
      " switch (a) {
      "   case 1 {
      "     break;
      "   }
    " -- g0
      " class asdf
      " {
      " public
      "   f();
      " private
      "   g();
      " }
    " -- t0
      " int
      " func() { ... }
    " -- (0
      " if (a && (b
      "           c)) { ... }
" cinkeys       keys that trigger C-indenting in Insert mode TODO
"       (local to buffer)
"       set cink=0{,0},0),:,0#,!^F,o,O,e
" cinwords      list of words that cause more C-indent TODO
"       (local to buffer)
"       set cinw=if,else,while,do,for,switch

" 15 folding

" foldenable    set to display all folds open
"       (local to window)
set fen
" foldlevel     folds with a level higher than this number will be closed
"       (local to window)
set fdl=1
" foldlevelstart        value for 'foldlevel' when starting to edit a file
" set fdls=1
" foldcolumn    width of the column used to indicate folds
"       (local to window)
"       set fdc=0
" foldclose     set to "all" to close a fold when the cursor leaves it
"       set fcl=
" foldopen      specifies for which commands a fold will be opened TODO
"       set fdo=block,hor,mark,percent,quickfix,search,tag,undo
" foldminlines  minimum number of screen lines for a fold to be closed TODO
"       (local to window)
"       set fml=1
" foldmethod    folding type: "manual", "indent", "expr", "marker" or "syntax"
"       (local to window)
set fdm=syntax
" foldmarker    markers used when 'foldmethod' is "marker" TODO
"       (local to window)
"       set fmr={{{,}}}
" foldnestmax   maximum fold depth for when 'foldmethod is "indent" or "syntax"
"       (local to window)
       set fdn=1

" 16 diff mode

" 17 mapping

" 18 reading and writing files
"
" modeline      enable using settings from modelines when reading a file
"       (local to buffer)
set ml
" modelines     number of lines to check for modelines
set mls=5
" shortname     use 8.3 file names
"       (local to buffer)
set nosn

" 19 the swap file TODO

" updatecount   number of characters typed to cause a swap file update
"       set uc=200
" updatetime    time in msec after which the swap file will be updated
"       set ut=4000
" maxmem        maximum amount of memory in Kbyte used for one buffer
"       set mm=510780
" maxmemtot     maximum amount of memory in Kbyte used for all buffers
"       set mmt=510780

" 20 command line editing

" history       how many command lines are remembered
set hi=50
" wildchar      key that triggers command-line expansion
set wc=9
" wildmode      specifies how command line completion works
" set wim=longest:list
" suffixes      list of file name extensions that have a lower priority
set su=.bak,~,.o,.h,.info,.swp,.obj,.info,.aux,.log,.dvi,.bbl,.out,.o,.lo
" wildmenu      command-line completion shows a list of matches
set nowmnu

" 21 executing external commands

" 22 running make and jumping to errors

" 23 language specific

" 24 multi-byte characters

" encoding      character encoding used in Vim: "latin1", "utf-8"
"       "euc-jp", "big5", etc.
set enc=utf-8

" 25 various

" --- Klavesove zkratky v StandBy mode
"Prace s Buffery
"ulozi a prepne na dalsi buffer
nmap <F2> :bn<CR>
"ulozi a prepne na predchozi buffer
nmap <F1> :bp<CR>
"vypise buffery
nmap <F3> :buffers<CR>
" Kompilace
"ulozi soubor a prelozi makefilem
nmap <F9> :wall<CR>:make<CR>
" Okna
" svisle rozdeli
nmap <F4> :vsplit<CR>
" prechod do dalsiho okna
nmap <TAB> <C-w><C-w>
" Chyby
" predchozi chyba
nmap <F5> :cprev<CR>
" nasledujici chyba
nmap <F6> :cnext<CR>
"vypis chyb
nmap <F7> :clist<CR>
" Ostatni
" zapne podporu mysi
nmap <F10> :setlocal mouse=a<CR>
" zapne/vypne paste rezim
nmap <F11> :setlocal invpaste<CR>
" zapne/vypne kontrolu slov
nmap <F12> :setlocal invspell<CR>

" --- Klavesove zkratky v Insert mode
"Prace s Buffery
" prepne na dalsi buffer
imap <F2> <ESC><ESC>:bn<CR>
" prepne na predchozi buffer
imap <F1> <ESC><ESC>:bp<CR>
"vypise buffery
imap <F3> <ESC><ESC>:buffers<CR>

" Kompilace
"ulozi soubor a prelozi makefilem
imap <F9> <ESC><ESC>:wall<CR>:make<CR>

" Ostatni
" zapne/vypne paste rezim
imap <F11> <ESC><ESC>:setlocal invpaste<CR>i


" zvyrazneni v Latex \emph{<vybrany_text>}
map <F8> xi\emph{<Esc>pa}<Esc>

" Highlight


" highlight 120 column for coding
set colorcolumn=80,120

hi link TrailingWhitespace Error
match TrailingWhitespace /\s\+$/

colorscheme aranel
set t_Co=256

"autocmd BufWritePre * :%s/\s\+$//e
"Relative line number:
set rnu
