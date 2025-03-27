#! /bin/bash

#Version 0 

#Funcion que muestra informacion acerca del funcionamiento del script
ayuda() {
        echo "sudo ./$(basename "$0")"
        echo "Script que permite la creación y configuración de usuarios"
        echo "Parametros: Ninguno, unicamente se necesita ejecutar el script como 'Root' o en su defecto usando 'sudo', ademas de tener algunos elementos previamente creados."
}

#Llamadas a la funcion de ayuda por parte del usuario
test "$1" == "-h" && { ayuda; exit; }
test "$1" == "--help" && { ayuda; exit; }

#Funcion que se encarga de mostrar un mensaje de acuerdo al contexto y de recibir los datos adecuados segun la funcion que lo invoque
datos() {
        local mensaje="$1"
        local valor=""
        while true;
        do
                read -p "$mensaje" valor
                if [ -n "$valor" ];
                then
                        break
                else
                        echo "Intente de nuevo"
                fi
        done
        echo "$valor"
}

#Funcion que se encarga de recibir una cadena, que sea evaluada para ser una contrasena segura
val_contrasena() {
    local contrasena=""
    while true;
    do
        read -s -p "Ingrese una contraseña (minimo 8 caracteres, una mayuscula, una minuscula, un numero y un caracter especial): " contrasena
        if [[ ${#contrasena} -ge 8 && "$contrasena" == *[A-Z]* && "$contrasena" == *[a-z]* && "$contrasena" == *[0-9]* && "$contrasena" == *[@#$%^+=]* ]];
        then
            break
        else
            echo "Error: La contrasena debe tener al menos 8 caracteres, una mayuscula, una minuscula, un numero y un caracter especial."
        fi
    done
    echo "$contrasena"
}

#Funciones que invocan a la funcion datos acompanado de la descripcion de los parametros
nombre() { datos "Ingrese el nombre completo del usuario: "; }
direccion() { datos "Ingrese el directorio del nuevo usuario (ejemplo -> /home/usuario/ ): "; }
plantilla() { datos "Ingrese el directorio que se usara como plantilla (predeterminado -> /etc/skel ): "; }
grupo() { datos "Ingresar el nombre del grupo que pertenece el usuario (el grupo debe estar previamente creado): "; }
shell_opt() { datos "Ingresa el directorio del shell predeterminado (predeterminado -> /bin/bash ): "; }
usuario() { datos "Ingresa el nombre (nickname) del usuario (no usar espacios): "; }

#Menu principal donde el usuario podra escoger diversas opciones segun su necesidad
select opt in "Crear usuario" "Salir" ;
do
        if [ "$opt" = "Crear usuario" ];
        then
	    #Llamada a las funciones necesarias para ejecutar el comando "useradd"
                name=$(nombre)
                dir=$(direccion)
                skel=$(plantilla)
                group=$(grupo)
                shell=$(shell_opt)
                nickname=$(usuario)
                password=$(val_contrasena)

                if [ -z "$password" ];
                then
                        echo "Error: No se ha ingresado una contrasena valida"
                        exit 1
                fi

		#Verifica que el usuario no este creado previamente
                if id "$nickname" &>/dev/null;
                then
                        echo "El usuario ""$nickname"" ya existe"
                        exit 1
                fi

		#Creacion del nuevo usuario
                useradd -c "$name" -d "$dir" -m -k "$skel" -g "$group" -s "$shell" "$nickname"

		#Asignacion de la contrasena al usuario
                echo 
                echo "Usuario: $nickname, Contrasena: $password"
                echo "$nickname:$password" | chpasswd

                if [ $? -ne 0 ];
                then
                        echo "Error al asignar la contrasena"
                        exit 1
                fi
 
                echo "Done! Usuario : ""$nickname"" creado correctamente."
                exit 0
        elif [ "$opt" = "Salir" ];
        then
                echo "Bye"
                exit 0
        else
                clear
                echo "Error"
                exit 1
        fi
done
