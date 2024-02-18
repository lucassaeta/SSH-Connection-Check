#!/bin/bash

# funcion para mostrar menu de ayuda
mostrarAyuda() {
    echo "MENU DE AYUDA (-h) SSH SCRIPT"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    echo "Este script comprueba inicios de sesion exitosos utilizando RSA y passphrase en una lista proporcionada de usuarios y sus ips."
    echo "-----------------------------------------------------------------------------------------------------------------------"
    echo "USO: $0 -u <nombre_usuario> -l <archivo_lista> -k <ruta_a_clave_privada_usuario>                  Ejecutar script"
    echo "USO: $0 -h                                                                                        Mostrar menu de ayuda"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    echo "RECORDATORIOS: "
    echo "--> nombre_usuario debe de ser el mismo nombre de usuario en todas las maquinas listadas por ip en la lista. Ejemplo: -u ubuntu"
    echo "--> archivo_lista debe seguir el formato: ip linea por linea. Ejemplo: 10.0.2.15 y en la siguiente linea 10.0.2.17"
    echo -e "--> ruta_a_clave_privada_usuario debe de ser la ruta la donde este la clave privada almacenada. Ejemplo: -k /home/nombreusuario/.ssh/id_rsa \n"
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

usuario=""
archivo_lista=""
clave_privada=""

# procesar las opciones de línea de comandos
while getopts ":hu:l:k:" opcion; do 
    case $opcion in 
        u) usuario="$OPTARG";;
        l) archivo_lista="$OPTARG";;
        k) clave_privada="$OPTARG";;
        h) mostrarAyuda;;
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

if [ ! -f "$clave_privada" ]; then
    echo "Falta archivo de lista o ruta de clave privada no válida."
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

while IFS= read -r ip; do
    if [[ -z "$ip" ]]; then
        continue # Salta líneas vacías
    fi
    # Llama al script de expect pasando usuario, IP y passphrase
    ./ssh_login_expect.sh "$usuario" "$ip" "$passphrase" "$clave_privada" >> "$logFile" 2>&1

done < "$archivo_lista"

echo "EJECUCION FINALIZADA! COMPRUEBE ARCHIVO DE LOGS GENERADO 'conexionLogs.txt' PARA VER EL INFORME FINAL DE LOS RESULTADOS."