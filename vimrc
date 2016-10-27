".vimrc from Andreas Meier
"Latest change: Do Mär 05 19:25:47 CET 2009


"statuszeile
set laststatus=2
set statusline=
set statusline+=%-3.3n\                      " buffer nummer
set statusline+=%f\                          " dateiname
set statusline+=%h%m%r%w                     " status flags
set statusline+=\[%{strlen(&ft)?&ft:'none'}] " dateityp
set statusline+=%=                           " folgendes rechts
set statusline+=0x%-8B                       " hex-wert des zeichens
set statusline+=%-14(%l,%c%V%)               " zeile, zeichen
set paste
set autoindent
set showmatch
set ignorecase
"Zeilennummerirung
"set nu
"suchergebnisse hilighten
set hlsearch
"muttng support
au BufNewFile,BufRead muttng-*-\w\+,muttng\w\{6\},ae\d setf mail
""Mit [F8] Automatisches Einruecken und Treppeneffekt beim Copy & Paste verhindern
set pastetoggle=<F8>
"viminfo
set viminfo='10,\"30,:20,%,n~/.viminfo
" cursor-position anzeigen
set ruler
" zur sicherheit machen wir backups
"set backup
"zur sicherheit nehmen wir einbackupdir ( mkdir -p ~/vimbackup )
"set backupdir=~/vimbackup
"wir benutzen dunklen hintergrund 
set background=dark
"wir moechten smartindent
set smartindent
"mit suche am anfang fortfahren wenn ende der datei erreicht ist
set wrapscan
"zeige den befehl immer
set showcmd
"ersetze tabs mit » und leerzeichen mit ·
"set list listchars=tab:\.\
"nach 75 zeichen eine swap datei schreiben
set uc=75
"wir wollen vim und nicht vi 
set nocompatible
" bei bearbeitung immer bei letzter position beginnen
au BufReadPost * if line("'\"") | exe "'\"" | endif
"loeschen einfacher machen
set bs=indent,eol,start

map <F2><F2> :set cursorcolumn! cursorline!<cr>
hi CursorColumn term=none ctermbg=red
hi Cursorline term=none ctermbg=blue

"========================
" Syntaxhiglighting
"========================
let color = "true"

if has("syntax")
    if color == "true"
        " schaltet colors an
        so ${VIMRUNTIME}/syntax/syntax.vim
            else
        " schaltet colors aus
            syntax off
            set t_Co=0
            endif
     endif
"========================
"========================

" Datum der letzten Aenderung eintragen
iab YDATE <C-R>=strftime("*** %a %b %d %T %Z %Y [Dein Name]")<CR>

map ,lc  1G/Latest change:\s*/e+1<CR>CXDATE<ESC>
iab XDATE <C-R>=strftime("%a %b %d %T %Z %Y")<CR>

" 2x ESC syntax ein/aus schalten
map <esc><esc> :if exists("syntax_on")\| syntax off\| else\| syntax on\| endif

" Umlaute in ASCII
"imap ä ae
"imap ö oe
"imap ü ue
"imap ß ss
"imap Ä Ae
"imap Ö Oe
"imap Ü Ue
"Kleinen Gruss beim Verlassen
au VimLeave * echo "The best editor :) greets from Andreas Meier a la' SkyAndy"

set expandtab
set softtabstop=4
set tabstop=4
set shiftwidth=4


