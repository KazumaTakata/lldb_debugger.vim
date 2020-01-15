
let g:res = ""
let g:sent_command = ""
sign define piet text=>> texthl=Search




fun! Parse_source_info(input) 
    let data = split(a:input, ":") 
    "echom join(data, "\n")
    let l:path = trim(data[1])
    let l:lnum = trim(data[2])
    return {"path": l:path, "lnum": l:lnum}
endfun


fun! Send_set_breakpoint_fun(channel, func_name)
    let g:sent_command = "set_breakpoint"
    let l:command = "breakpoint set --name" . a:func_name .  "\n"
    return ch_evalraw(a:channel,l:command)  
endfun

fun! Send_next(channel)
    let g:sent_command = "next"
    let l:command = "next\n"
    return ch_evalraw(a:channel,l:command)  
endfun



fun! Send_run(channel)
    let g:sent_command = "run"
    let l:command = "run" . "\n"
    return ch_evalraw(a:channel,l:command) 

endfun


fun! Send_get_filepath_lnum(channel)
    let g:sent_command = "source_info"
    let l:command = "source info" . "\n"
    return ch_evalraw(a:channel,l:command) 
endfun

fun! MyHandler(msg)
    call writefile([a:msg], "log", "a")
"    echom a:msg
    let g:res = a:msg
    
    if  a:msg[0] == "["
        let path_lnum = Parse_source_info(a:msg)
"        echom "path is " . path_lnum.path . " lnum is " . path_lnum.lnum 
        call Go_to(path_lnum)
    endif

endfun


fun! Go_to(path_lnum)
    execute "edit ". a:path_lnum.path
    call cursor(a:path_lnum.lnum, 0) 
    exe ":sign place 2 line=". a:path_lnum.lnum ." name=piet file=" . expand("%:p")     
    echom "aaa"
    redraw!
endfun


fun! Show_stack_env()
    pedit stack
    noautocmd wincmd P
    set buftype=nofile
    call append(0, "variable in stack")
    noautocmd wincmd p
endfun


fun! Read_all(channel)
    let buf = [] 
     
    while 1 
    let output = ch_readraw(a:channel)
    if output == "" || stridx(output, "stopped.") > 0
        break
    endif 
    call add(buf, output)
    endwhile
    
    return buf

endfun

let exe_name = input('executable file: ')



let job = job_start("lldb ". exe_name , {"drop": "never"})

"let job = job_start("lldb ".exe_name , {"drop": "never" ,"out_cb": "MyHandler"})


let channel = job_getchannel(job)

let output =  ch_evalraw(channel, "breakpoint set --name main\n")  
let output = Read_all(channel)


let output = Send_run(channel)
let output = Read_all(channel)

call Send_next(channel)
call Read_all(channel)

let output = Send_get_filepath_lnum(channel)
let output = Read_all(channel)

for line in output 
    call MyHandler(line)
endfor

while 1
    let input_data = input('command: ')
    if input_data == "next"
        call Send_next(channel)
        call Read_all(channel)

        let output = Send_get_filepath_lnum(channel)
        let output = Read_all(channel)

        for line in output 
            call MyHandler(line)
        endfor
    
    elseif input_data == "quit"
        break
    endif 


    



endwhile



"echom output


