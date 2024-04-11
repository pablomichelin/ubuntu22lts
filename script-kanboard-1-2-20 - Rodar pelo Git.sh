#!/bin/bash

# Define o ambiente como não interativo e força a aceitação de novas versões de configurações
export DEBIAN_FRONTEND=noninteractive

# Adiciona o PPA para PHP 8.1
echo "Adicionando o PPA para PHP 8.1..."
sudo -E apt-get -y install software-properties-common
sudo -E add-apt-repository ppa:ondrej/php -y
sudo -E apt-get update

# Atualiza o sistema sem interações
echo "Atualizando o sistema..."
sudo -E apt-get -y -o Dpkg::Options::="--force-confnew" upgrade

# Instala o Nginx sem interações
echo "Instalando o Nginx..."
sudo -E apt-get -y install nginx

# Verifica the status do Nginx
echo "Verificando o status do Nginx..."
systemctl status nginx

# Instala o PHP 8.1 e extensões necessárias sem interações
echo "Instalando o PHP 8.1 e extensões necessárias..."
sudo -E apt-get -y install php8.1-fpm php8.1-cli php8.1-mbstring php8.1-xml php8.1-zip php8.1-sqlite3 php8.1-curl php8.1-gd

# Baixa a última versão do Kanboard
echo "Baixando a última versão do Kanboard..."
cd /var/www/html
sudo wget https://github.com/kanboard/kanboard/archive/refs/tags/v1.2.20.tar.gz

# Descompacta o arquivo e ajusta o diretório
echo "Descompactando o Kanboard e ajustando o diretório..."
sudo tar -xzvf v1.2.20.tar.gz
sudo mv kanboard-1.2.20 kanboard
sudo chown -R www-data:www-data /var/www/html/kanboard

# Verifica se um endereço IP ou nome de domínio foi passado como argumento
if [ -z "$1" ]; then
    echo "Nenhum endereço IP ou nome de domínio fornecido como argumento. Saindo..."
    exit 1
else
    server_ip=$1
fi

# Configura o Nginx para o Kanboard
echo "Configurando o Nginx para o Kanboard..."
sudo bash -c "cat > /etc/nginx/sites-available/kanboard << EOF
server {
    listen 80;
    server_name $server_ip;

    root /var/www/html/kanboard;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF"

# Ativa a configuração e recarrega o Nginx
echo "Ativando a configuração do Nginx e recarregando..."
sudo ln -s /etc/nginx/sites-available/kanboard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

echo "Instalação do Kanboard concluída."