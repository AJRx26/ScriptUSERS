#! /bin/bash

#Version 0 

#Funcion que muestra informacion acerca del funcionamiento del script
ayuda() {
        echo "sudo ./$(basename "$0")"
        echo "Script que permite la creación/configuración de usuarios ademas de la creacion de grupos para contener a los usuarios"
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
        #P.d Intente basarme en el script dado en Admin. de Servidores pero no era compatible, asi que tuve que "adaptarlo"
        if [[ ${#contrasena} -ge 8 && "$contrasena" == *[A-Z]* && "$contrasena" == *[a-z]* && "$contrasena" == *[0-9]* && "$contrasena" == *[@#$%^+=]* ]];
        then
            break
        else
            echo "Error: La contrasena debe tener al menos 8 caracteres, una mayuscula, una minuscula, un numero y un caracter especial."
        fi
    done
    echo "$contrasena"
}

#Funcion que se encarga de asignar los permisos al usuario recien creado
dar_permisos() {
    local comandos=""
    local nickname="$1"

    read -p "Ingrese el nivel de permisos que puede tener con sudo (comandos especificos separados por comas o '*' para todos los permisos): " comandos
    #Se obtiene el archivo para configurar los permisos del usuario
    sudo_file="/etc/sudoers.d/$nickname"

    if [[ "$comandos" == "*" ]];
    then
        echo "$nickname ALL=(ALL) ALL" | sudo tee "$sudo_file" > /dev/null
    else
        echo "$nickname ALL=(ALL) NOPASSWD: $(echo $comandos | tr ',' ', ')" | sudo tee "$sudo_file" > /dev/null
    fi

    echo "Configuración de sudo aplicada para $nickname."
}

#Funciones que invocan a la funcion datos acompanado de la descripcion de los parametros
nombre() { datos "Ingrese el nombre completo del usuario: "; }
direccion() { datos "Ingrese el directorio del nuevo usuario (ejemplo -> /home/usuario/ ): "; }
plantilla() { datos "Ingrese el directorio que se usara como plantilla (predeterminado -> /etc/skel ): "; }
grupo() { datos "Ingresar el nombre del grupo que pertenece el usuario (el grupo debe estar previamente creado): "; }
shell_opt() { datos "Ingresa el directorio del shell predeterminado (predeterminado -> /bin/bash ): "; }
usuario() { datos "Ingresa el nombre (nickname) del usuario (no usar espacios): "; }
grupo() { datos "Ingrese nombre del grupo que desea crear: "; }

#Menu principal donde el usuario podra escoger diversas opciones segun su necesidad
select opt in "Crear usuario" "Crear grupo" "Salir" ;
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

                # Configurar permisos del usuario creado
                read -p "¿Desea que el usuario $nickname tenga permisos de sudo? (s/n): " sudo_permiso
                if [[ "$sudo_permiso" == "s" ]];
                then
                    dar_permisos "$nickname"
                fi
                continue
 
                echo "Done! Usuario : ""$nickname"" creado correctamente."
                continue

        elif [ "$opt" = "Crear grupo" ];
        then
        #Obtiene el nombre del grupo de parte del usuario
                name_group=$(grupo)

                #Verifica que el nombre introducido este libre, es decir, que no exista anteriormente
                if getent group "$name_group" &>/dev/null;
                then
                        echo "El grupo ""$name_group"" ya existe"
                        continue
                fi

                #Crear el grupo
                groupadd "$name_group"

                echo "Done! Grupo : ""$name_group"" creado correctamente."
                continue

        elif [ "$opt" = "Salir" ];
        then
                echo "Bye"
                exit 0
        else
        #Muestra que el usuario ha introducido un valor incorrecto
                clear
                echo "Error, opcion no valida"
                continue
        fi
done
