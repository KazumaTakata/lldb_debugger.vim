
let g:res = ""
let g:sent_command = ""
sign define piet text=>> texthl=Search




fun! Parse_source_info(input) 
    let data = split(a:input, ":") 
    echom join(data, "\n")
    let l:path = trim(data[1])
    let l:lnum = trim(data[2])
    return {"path": l:path, "lnum": l:lnum}
endfun


fun! Send_set_breakpoint_fun(channel, func_name)
    let g:sent_command = "set_breakpoint"
    let l:command = "breakpoint set --name" . a:func_name .  "\n"
    call ch_sendraw(a:channel,l:command)  
endfun


fun! Send_run(channel)
    let g:sent_command = "run"
    let l:command = "run" . "\n"
    call ch_sendraw(a:channel,l:command) 
endfun


fun! Send_get_filepath_lnum(channel)
    let g:sent_command = "source_info"
    let l:command = "source info" . "\n"
    call ch_sendraw(a:channel,l:command) 
endfun

fun! MyHandler(ch, msg)
    call writefile([a:msg], "log", "a")
    echom a:msg
    let g:res = a:msg
    
    if g:sent_command == "source_info" &&  a:msg[0] == "["
        let path_lnum = Parse_source_info(a:msg)
        echom "path is " . path_lnum.path . " lnum is " . path_lnum.lnum 
        call Go_to(path_lnum)
    endif
endfun


fun! Go_to(path_lnum)
    execute "edit ". a:path_lnum.path
    call cursor(a:path_lnum.lnum, 0) 
    exe ":sign place 2 line=". a:path_lnum.lnum ." name=piet file=" . expand("%:p")     
endfun


fun! Show_stack_env()
    pedit stack
    noautocmd wincmd P
    set buftype=nofile
    call append(0, "variable in stack")
    noautocmd wincmd p
endfun


"let job = job_start("cat", {"drop": "never"})

let job = job_start("lldb a.out", {"out_cb": "MyHandler"})


let channel = job_getchannel(job)
call ch_sendraw(channel, "breakpoint set --name main\n")  
call Send_run(channel)

