#!/usr/bin/expect -f

#NOTAS PROGRAMADOR: 
#shebang que indica que el script debe ser ejecutado con expect en modo no interactivo
#-->permite la automatizacion de scripts que interactuan con programas que normalmente requieren entrada del usuario

#exp_continue: reinicia la busqueda de patrones sin salir del bloque expect actual. se utiliza para manejar multiples interacciones dentro de la misma conexion o proceso
#-re: indica uso de expresion regular
#lindex: acceder a un elemento específico de una lista en tcl
#eof: end of file, indica final de proceso 
#puts: basicamente un printf de tcl

# asigna los argumentos pasados desde el script
set usuario [lindex $argv 0]
set ip [lindex $argv 1]
set passphrase [lindex $argv 2]

# deshabilita la impresion de la salida de los comandos del terminal para mantener la fichero limpio
log_user 0

# inicia la conexion SSH
spawn ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$usuario@$ip"

# define un patron de prompt generico que se espera ver en una shell generada con exito
set prompt "(%|#|\\$|>) $"

# espera multiples posibles respuestas del proceso spawn
expect {
    # si se detecta un prompt de passphrase, envia el passphrase proporcionado
    "passphrase" {
        send "$passphrase\r"
        exp_continue
    }
    # cubre una posible variante de prompt de passphrase en espaniol
    "clave" {
        send "$passphrase\r"
        exp_continue
    }
    # si se encuentra un prompt de shell
    -re $prompt {
        puts "LOGIN EXITOSO en $usuario@$ip"
        exit
    }
    # si el proceso termina (EOF)
    eof {
        puts "LOGIN ERROR en $usuario@$ip"
        exit
    }
    # si se alcanza el tiempo de espera sin una respuesta
    timeout {
        puts "LOGIN ERROR en $usuario@$ip"
        exit
    }
}

# espera el final del proceso antes de terminar el script
expect eof
