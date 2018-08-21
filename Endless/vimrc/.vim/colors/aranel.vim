" Vim color file
" Maintainer:	David Schweikert <dws@ee.ethz.ch>
" Last Change:	2006 Apr 30

hi clear

let colors_name = "aranel"

hi LineNr cterm=bold

hi Question cterm=bold ctermfg=Green
hi Type cterm=bold ctermfg=Green
hi link Typedef Type
hi link Structure Type
hi link MoreMsg Type

hi Number ctermfg=5

hi PreProc cterm=bold ctermfg=4

hi Special ctermfg=Red

hi Statement cterm=bold

hi Comment ctermfg=6

hi Constant ctermfg=13

hi SpecialKey ctermfg=4

hi Visual ctermbg=8


hi _Positive cterm=bold ctermfg=Green
hi _Negative cterm=bold ctermfg=Red

hi link GentooPackageUseUse _Positive
hi link GentooPackageUseUnuse _Negative

hi TabLineFill cterm=reverse ctermfg=7

highlight User1 ctermbg=5 ctermfg=black
highlight User2 ctermbg=7 ctermfg=black
highlight User3 ctermbg=7 ctermfg=red


highlight ColorColumn ctermbg=8

" vim: sw=2
