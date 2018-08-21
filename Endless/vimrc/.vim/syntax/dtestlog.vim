" Vim syntax file
" Language: Dtests logs
" Maintainer: Zdenek Kraus <zkraus@redhat.com>
" Latest Version: May 12 2014

if exists("b:dtestlog")
  finish
endif

highlight DTestINFO ctermfg=8
highlight DTestERROR ctermfg=red
highlight DTestWARNING ctermfg=11
highlight DTestDEBUG ctermfg=6

highlight DTestPASS cterm=bold ctermfg=green
highlight DTestFAIL cterm=bold ctermfg=red

highlight DTestName cterm=bold ctermfg=6
highlight DTestTCGName ctermfg=6
highlight DTestDSchema ctermfg=5

highlight link DTestString Constant
highlight link DTestString2 Constant

highlight DTestRemote cterm=bold

syntax keyword DTestINFO INFO nextgroup=DTestRemote
syntax keyword DTestERROR ERROR nextgroup=DTestRemote
syntax keyword DTestWARNING WARNING nextgroup=DTestRemote
syntax keyword DTestDEBUG DEBUG nextgroup=DTestRemote

syntax keyword DTestPASS PASS
syntax keyword DTestFAIL FAIL

syntax match DTestRemote /:[a-zA-Z0-9_.]\+:/ contained


" syntax region DTestString start="'" end="'"
" syntax region DTestString2 start='"' end='"'

" syntax match DTestPass /\s\+PASS\s\+/
" syntax match DTestFail /\s\+FAIL\s\+/
"

syntax match DTestDSchema /DS[a-zA-Z0-9]\+/
syntax match DTestName /test_[^ ]\+/
syntax match DTestTCGName /[A-Z][a-zA-Z0-9_]*Tests/ contains=DTestName




