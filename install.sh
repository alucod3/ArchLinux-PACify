#!/bin/bash

# Verificar se está sendo executado como root
if [[ $EUID -ne 0 ]]; then
	echo "Ops... Este script precisa ser executado como superusuário (root)" 
   exit 1
fi

###
# START BANNER
###

cat << EOF
______  ___  _____ _  __       
| ___ \/ _ \/  __ (_)/ _|      
| |_/ / /_\ \ /  \/_| |_ _   _ 
|  __/|  _  | |   | |  _| | | |
| |   | | | | \__/\ | | | |_| |
\_|   \_| |_/\____/_|_|  \__, |
                          __/ |
                         |___/ 
				
			by alucod3

kekw I Use Arch Btw

EOF

#!/bin/bash

# Função para exibir uma mensagem e ler a resposta do usuário
get_user_confirmation() {
    echo "Deseja prosseguir com o script? (S/N)"
    read resposta
    resposta=$(echo "$resposta" | tr '[:lower:]' '[:upper:]')
}

# Função para executar comandos e verificar se tiveram sucesso
run_command() {
    local command="$1"
    echo "Executando: $command"
    if eval "$command"; then
        echo "Comando executado com sucesso."
    else
        echo "Erro ao executar: $command"
        return 1
    fi
}

# Função para instalar pacotes
install_packages() {
    local packages="$@"
    run_command "sudo pacman -S --noconfirm $packages"
}

# Função para configurar o Picom
configure_picom() {
    mkdir -p ~/.config/autostart
    echo "[Desktop Entry]
Type=Application
Name=Picom
Exec=picom --config ~/.config/picom/picom.conf
" > ~/.config/autostart/picom.desktop

    mkdir -p ~/.config/picom
    if [ ! -f ~/.config/picom/picom.conf ]; then
        echo "# Exemplo de configuração básica do Picom
backend = \"glx\";
blur-background = true;
blur-method = \"dual_kawase\";
" > ~/.config/picom/picom.conf
    fi
}

# Função para configurar o i3
configure_i3() {
    local i3_config="$HOME/.config/i3/config"
    local picom_config="$HOME/.config/picom.conf"
    if ! grep -q "exec --no-startup-id picom" "$i3_config"; then
        cat <<EOF >> "$i3_config"
# Iniciar picom para transparências e sombras
exec --no-startup-id picom --experimental-backends --backend glx --config "$picom_config"
EOF
    fi
}

# Função para instalar e configurar Zsh e Oh My Zsh
install_zsh() {
    run_command "sudo pacman -Sy --noconfirm zsh"
    run_command "sudo chsh -s $(which zsh) $USER"
    run_command "sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"
}

# Função para baixar e instalar uma fonte
install_font() {
    local font_url="$1"
    local temp_dir="/tmp/fonts"
    local font_dir="/usr/share/fonts/Nerd Fonts"
    local font_zip=$(basename "$font_url")

    # Cria o diretório temporário e de destino, se não existirem
    run_command "mkdir -p $temp_dir"
    run_command "sudo mkdir -p \"$font_dir\""

    # Baixa a fonte
    run_command "curl -L -o \"$temp_dir/$font_zip\" \"$font_url\""

    # Descompacta a fonte
    run_command "sudo unzip -o \"$temp_dir/$font_zip\" -d \"$font_dir\""

    # Atualiza o cache de fontes
    run_command "sudo fc-cache -vf \"$font_dir\""

    echo "Fonte instalada com sucesso em $font_dir."
}

# Lista de URLs de fontes
font_urls=(
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
    # Adicione mais URLs de fontes aqui
)

# Função para configurar ambiente de desenvolvimento
configure_dev_environment() {
    run_command "sudo pacman -S neovim --noconfirm"
    run_command "LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh)"
    run_command "sudo pacman -S alacritty gcc go --noconfirm"
    echo 'export GOPATH="$HOME/go"' >> ~/.zshrc
    echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.zshrc
}

# Função para detectar e instalar drivers de placa de vídeo
configure_graphics() {
    echo "Detectando placa de vídeo..."
    if lspci | grep -i nvidia &> /dev/null; then
        echo "Placa de vídeo NVIDIA detectada. Instalando drivers..."
        run_command "sudo pacman -S nvidia nvidia-settings nvidia-utils --noconfirm"
        run_command "sudo modprobe nvidia"
        run_command "sudo systemctl enable nvidia-persistenced.service"
        run_command "nvidia-settings --assign CurrentMetaMode=\"nvidia-auto-select +0+0 { ForceCompositionPipeline = On }\""
    elif lspci | grep -i amd &> /dev/null; then
        echo "Placa de vídeo AMD detectada."
        echo "Instalação de drivers AMD ainda não suportada neste script."
        exit 1
    else
        echo "Não foi possível detectar uma placa de vídeo NVIDIA ou AMD compatível."
        exit 1
    fi
}

# Solicita confirmação do usuário
get_user_confirmation

# Verifica a resposta do usuário
if [ "$resposta" = "S" ]; then
    echo "Atualizando e iniciando instalações..."

    # Atualiza a lista de pacotes e o sistema
    run_command "sudo pacman -Syu --noconfirm"

    # Instala pacotes e configurações essenciais
    install_packages i3-wm i3status i3lock i3bar dmenu feh rxvt-unicode xcb-util xcb-util-keysyms xcb-util-wm rofi picom xorg xinit xdotool xrdb ranger htop newsboat git
    configure_picom
    configure_i3

    # Instala e configura Zsh e Oh My Zsh
    install_zsh

    # Instala fontes
    install_fonts

    # Configura ambiente de desenvolvimento
    configure_dev_environment

    # Configura drivers de placa de vídeo
    configure_graphics

    # Atualiza novamente a lista de pacotes
    run_command "sudo pacman -Syyu --noconfirm"

    echo ""
    echo "Script concluído com sucesso."
    echo ""

elif [ "$resposta" = "N" ]; then
    echo "Encerrando o script."
    exit 0
else
    echo "Resposta inválida. Por favor, responda S ou N."
    exit 1
fi
