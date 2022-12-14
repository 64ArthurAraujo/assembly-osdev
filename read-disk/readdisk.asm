; loads 'dh' sectors from drive 'dl' into ES:BX
disk_load:
    pusha

    ; reading from disk requires setting specific values in all registers
    ; so we will overwrite our input parameters from 'dx'. Let's save it
    ; to the stack for later use.
    push dx

    mov ah, 0x02 ; ah <- int 0x13 function. 0x02 = 'read'
    
    mov al, dh ; al <- number of sectors to read (0x01 .. 0x80)
    mov cl, 0x02 ; mov to cl the sector we want to read
                 ; since 0x01 is our boot sector, 0x02 is the first 'available' sector
    mov ch, 0x00 ; ch <- cylinder (0x0 .. 0x3FF, upper 2 bits in 'cl')
    ; dl <- drive number. Our caller sets it as a parameter and gets it from BIOS
    ; (0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2)
    mov dh, 0x00 ; dh <- head number (0x0 .. 0xF)

    ; [es:bx] <- pointer to buffer where the data will be stored
    ; caller sets it up for us, and it is actually the standard location for int 13h

    int 0x13 ; BIOS interrupt
    jc disk_err

    pop dx

    cmp al, dh ; BIOS also sets 'al' to the # of sectors read. Compare it.
    jne sectors_err

    jmp read_successful

disk_err:
    mov bx, disk_read_err
    call print
    call print_nl
    mov dh, ah ; ah = error code, dl = disk drive that dropped the error
    call print_hex

    jmp disk_loop

sectors_err:
    mov bx, sectors_not_equal_err
    call print

    jmp disk_loop

disk_loop:
    jmp $


read_successful:
    mov bx, disk_read_success
    call print

    call switch_to_pm


disk_read_err: db "Disk read error", 0
sectors_not_equal_err: db "Incorrect number of sectors read", 0

disk_read_success: db "Successfully read the disk!", 0