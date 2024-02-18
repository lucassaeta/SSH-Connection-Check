#!/bin/bash

# funcion para mostrar menu de ayuda
mostrarAyuda() {
    echo "MENU DE AYUDA (-h) SSH SCRIPT"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    echo "Este script comprueba inicios de sesion exitosos utilizando RSA y passphrase en una lista proporcionada de usuarios y sus ips."
    echo "-----------------------------------------------------------------------------------------------------------------------"
    echo "USO: $0 -l <archivo_lista>                                                          Ejecutar script"
    echo "USO: $0 -h                                                                          Mostrar menu de ayuda"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    echo "RECORDATORIOS: "
    echo "--> archivo_lista debe seguir el formato: usuarios:ips linea por linea. Ejemplo: 'ubuntu:10.0.2.15'."
    echo "--> Debe de estar instalado el paquete 'expect' para que el script funcione correctamente. Instalacion con comando: 'sudo apt install expect'. "
    echo "--> Se debe de tener las claves generadas de RSA. Si no se ha hecho, se debe utilizar el comando 'ssh-keygen' para generar claves y passphrase."
    echo "--> Se debe de haber copiado las claves publicas de maquinas remotas para poder hacer el login con passphrase y RSA. Si no se ha hecho, se tiene que ejecutar 'ssh-copy-id usuario@direccion_ip_remota'"
    exit 1
}

# verificar si expect esta instalado
if ! command -v expect &> /dev/null; then
    echo "ERROR: 'expect' no esta instalado. Por favor instalelo primero. Utilice el menu de ayuda para mas informacion (-h). "
    exit 1
fi

# verificar si ssh esta instalado
if ! command -v ssh &> /dev/null; then
    echo "ERROR: El servicio de SSH no esta instalado. Por favor instalelo primero."
    exit 1
fi

# verificar numero de parametros
if [ "$#" -eq 0 ]; then
    echo "ERROR: No se proporcionaron argumentos."
    mostrarAyuda
fi

archivo_lista=""

# procesar las opciones de línea de comandos
while getopts ":hl:" opcion; do 
    case $opcion in 
        l)
            archivo_lista="$OPTARG"
            ;;
        h) 
            mostrarAyuda
            ;;
        \?) # manejar opciones invalidas
            echo "ERROR: Opcion invalida: -$OPTARG"
            echo
            mostrarAyuda
            ;;
        :) # manejar opciones faltantes
            echo "ERROR: La opcion -$OPTARG requiere un argumento."
            echo
            mostrarAyuda
            ;;
    esac 
done

# verificar si el archivo de lista existe
if [ ! -f "$archivo_lista" ]; then
    echo "ERROR: El archivo de lista '$archivo_lista' no existe."
    exit 1
fi

# solicitar la contrasenia por teclado
echo -n "Introduzca el passphrase para conectarse a los usuarios: "
read -s passphrase
echo
echo "Este proceso puede durar bastante dependiendo del numero de usuarios en la lista."
echo "Por favor, espere pacientemente mientras se ejecutan las verificaciones..."
echo
logFile="conexionLogs.txt"
# sobrescribir/vaciar el archivo de log existente
> "$logFile"
echo "------------------------------------------------------------------" >> "$logFile"
echo "COMPROBACIONES CHECK LIST: " >> "$logFile"
echo "------------------------------------------------------------------" >> "$logFile"

while IFS=: read -r usuario ip
do
    # almacena la linea completa para el registro de errores
    linea="${usuario}:${ip}"

    # comprueba si la línea está vacia (para saltar lineas en blanco)
    if [ -z "$linea" ]; then
        continue
    fi

    # comprueba si el usuario o la ip estan vacios
    if [ -z "$usuario" ] || [ -z "$ip" ]; then
        echo "ERROR: Formato inválido en la línea de la lista: $linea"
        continue
    fi
  
    ./ssh_passphrase_expect.sh "$usuario" "$ip" "$passphrase" >> "$logFile"

done < "$archivo_lista"

echo "EJECUCION FINALIZADA! COMPRUEBE ARCHIVO DE LOGS GENERADO 'conexionLogs.txt' PARA VER EL INFORME FINAL DE LOS RESULTADOS."
