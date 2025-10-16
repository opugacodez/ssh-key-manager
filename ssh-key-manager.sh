#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SSH_DIR="$HOME/.ssh"
KEYS_DIR="$SSH_DIR/keys"
CONFIG_FILE="$SSH_DIR/config"
KNOWN_HOSTS="$SSH_DIR/known_hosts"

show_usage() {
    echo -e "${GREEN}SSH Key Manager - Gerenciador de Chaves SSH${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos:"
    echo "  create [serviço] [email]     Cria uma nova chave SSH para um serviço"
    echo "  list                         Lista todas as chaves gerenciadas"
    echo "  test [serviço]               Testa conexão com um serviço"
    echo "  delete [serviço]             Remove chave de um serviço"
    echo "  backup                       Faz backup das chaves"
    echo "  restore [arquivo]            Restaura chaves do backup"
    echo "  diagnose [serviço]           Diagnóstico detalhado"
    echo ""
    echo "Exemplos:"
    echo "  $0 create github usuario@email.com"
    echo "  $0 create gitlab usuario@empresa.com"
    echo "  $0 create bitbucket usuario@email.com"
    echo "  $0 list"
    echo "  $0 test github"
}

init_directories() {
    echo -e "${BLUE}📁 Inicializando estrutura de diretórios...${NC}"
    
    if [ ! -d "$SSH_DIR" ]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        echo -e "${GREEN}✓ Diretório SSH criado: $SSH_DIR${NC}"
    fi
    
    if [ ! -d "$KEYS_DIR" ]; then
        mkdir -p "$KEYS_DIR"
        chmod 700 "$KEYS_DIR"
        echo -e "${GREEN}✓ Diretório de chaves criado: $KEYS_DIR${NC}"
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        touch "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        echo -e "# SSH Config - Gerenciado por SSH Key Manager" > "$CONFIG_FILE"
        echo -e "# Configuração global" >> "$CONFIG_FILE"
        echo -e "Host *" >> "$CONFIG_FILE"
        echo -e "    AddKeysToAgent yes" >> "$CONFIG_FILE"
        echo -e "    IdentitiesOnly yes" >> "$CONFIG_FILE"
        echo -e "${GREEN}✓ Arquivo config criado: $CONFIG_FILE${NC}"
    fi
    
    if [ ! -f "$KNOWN_HOSTS" ]; then
        touch "$KNOWN_HOSTS"
        chmod 644 "$KNOWN_HOSTS"
        echo -e "${GREEN}✓ Arquivo known_hosts criado${NC}"
    fi
}

start_ssh_agent() {
    echo -e "${BLUE}🔑 Iniciando SSH Agent...${NC}"
    
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null 2>&1
    fi
    
    for key_file in "$KEYS_DIR"/id_*; do
        if [ -f "$key_file" ] && [[ ! "$key_file" == *.pub ]]; then
            ssh-add "$key_file" 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}✓ SSH Agent configurado${NC}"
}

create_key() {
    local service=$1
    local email=$2
    
    if [ -z "$service" ] || [ -z "$email" ]; then
        echo -e "${RED}Erro: Serviço e email são obrigatórios${NC}"
        show_usage
        return 1
    fi
    
    local key_file="$KEYS_DIR/id_${service}"
    
    if [ -f "${key_file}" ]; then
        echo -e "${YELLOW}⚠  Já existe uma chave para $service${NC}"
        read -p "Deseja sobrescrever? (s/N): " overwrite
        if [[ ! $overwrite =~ ^[Ss]$ ]]; then
            return 1
        fi
        rm -f "${key_file}" "${key_file}.pub"
    fi
    
    echo -e "${BLUE}🔐 Criando chave SSH para $service...${NC}"
    
    echo -e "${YELLOW}Escolha o tipo de chave:${NC}"
    echo "1) ed25519 (Recomendado - Mais seguro e rápido)"
    echo "2) rsa-4096 (Compatibilidade máxima)"
    read -p "Opção [1]: " key_type
    
    case $key_type in
        2|"rsa")
            key_type="rsa"
            key_bits="-b 4096"
            echo -e "${GREEN}✓ Usando RSA-4096${NC}"
            ;;
        *)
            key_type="ed25519"
            key_bits=""
            echo -e "${GREEN}✓ Usando Ed25519 (Recomendado)${NC}"
            ;;
    esac
    
    echo -e "${YELLOW}💡 Dica: Deixe o passphrase vazio para uso mais fácil${NC}"
    ssh-keygen -t $key_type $key_bits -C "$email" -f "$key_file" -N ""
    
    if [ $? -eq 0 ]; then
        chmod 600 "$key_file"
        chmod 644 "${key_file}.pub"
        
        add_to_config "$service"
        start_ssh_agent
        add_key_to_agent "$service"
        add_to_known_hosts "$service"
        show_public_key "$service"
        echo -e "${GREEN}✅ Chave para $service criada com sucesso!${NC}"
        echo -e "${YELLOW}📋 Não esqueça de adicionar a chave pública no $service${NC}"
    else
        echo -e "${RED}❌ Erro ao criar chave para $service${NC}"
        return 1
    fi
}

add_key_to_agent() {
    local service=$1
    local key_file="$KEYS_DIR/id_${service}"
    
    if [ -f "$key_file" ]; then
        ssh-add "$key_file" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Chave $service adicionada ao SSH Agent${NC}"
        else
            echo -e "${YELLOW}⚠  Chave $service já está no agent ou ocorreu um erro${NC}"
        fi
    fi
}

add_to_known_hosts() {
    local service=$1
    
    case $service in
        "github")
            host="github.com"
            ;;
        "gitlab")
            host="gitlab.com"
            ;;
        "bitbucket")
            host="bitbucket.org"
            ;;
        *)
            host="$service.com"
            ;;
    esac
    
    ssh-keygen -R "$host" > /dev/null 2>&1
    ssh-keygen -R "git.$host" > /dev/null 2>&1
    
    ssh-keyscan "$host" >> "$KNOWN_HOSTS" 2>/dev/null
    echo -e "${GREEN}✓ Host $host adicionado aos known_hosts${NC}"
}

add_to_config() {
    local service=$1
    local key_file="$KEYS_DIR/id_${service}"
    
    case $service in
        "github")
            host="github.com"
            ;;
        "gitlab")
            host="gitlab.com"
            ;;
        "bitbucket")
            host="bitbucket.org"
            ;;
        *)
            host="$service.com"
            ;;
    esac
    
    sed -i.bak "/^# $service - START/,/^# $service - END/d" "$CONFIG_FILE" 2>/dev/null
    
    cat >> "$CONFIG_FILE" << EOL

# $service - START - Created $(date)
Host $service $host
    HostName $host
    User git
    IdentityFile $key_file
    IdentitiesOnly yes
    AddKeysToAgent yes
# $service - END

EOL
    
    echo -e "${GREEN}✓ Configuração adicionada para $service${NC}"
}

show_public_key() {
    local service=$1
    local pub_file="$KEYS_DIR/id_${service}.pub"
    
    if [ -f "$pub_file" ]; then
        echo -e "${YELLOW}📋 CHAVE PÚBLICA para $service (copie e cole no site):${NC}"
        echo ""
        cat "$pub_file"
        echo ""
        echo -e "${GREEN}📍 URL para adicionar a chave:${NC}"
        
        case $service in
            "github")
                echo -e "🌐 https://github.com/settings/ssh/new"
                ;;
            "gitlab")
                echo -e "🌐 https://gitlab.com/-/profile/keys"
                ;;
            "bitbucket")
                echo -e "🌐 https://bitbucket.org/account/settings/ssh-keys/"
                ;;
        esac
        
        if command -v pbcopy >/dev/null; then
            cat "$pub_file" | pbcopy
            echo -e "${GREEN}✅ Chave copiada para clipboard (macOS)${NC}"
        elif command -v xclip >/dev/null; then
            cat "$pub_file" | xclip -selection clipboard
            echo -e "${GREEN}✅ Chave copiada para clipboard (Linux)${NC}"
        elif command -v wl-copy >/dev/null; then
            cat "$pub_file" | wl-copy
            echo -e "${GREEN}✅ Chave copiada para clipboard (Wayland)${NC}"
        else
            echo -e "${YELLOW}⚠  Copie manualmente a chave acima${NC}"
        fi
    else
        echo -e "${RED}❌ Arquivo de chave pública não encontrado: $pub_file${NC}"
    fi
}

list_keys() {
    echo -e "${BLUE}📋 Chaves SSH Gerenciadas:${NC}"
    echo ""
    
    if [ ! -d "$KEYS_DIR" ] || [ -z "$(ls -A "$KEYS_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}Nenhuma chave encontrada${NC}"
        return
    fi
    
    for key_file in "$KEYS_DIR"/*.pub; do
        if [ -f "$key_file" ]; then
            local service=$(basename "$key_file" .pub | sed 's/id_//')
            local email=$(awk '{print $3}' "$key_file")
            local created=$(stat -c "%y" "$key_file" 2>/dev/null | cut -d'.' -f1)
            local key_type=$(ssh-keygen -lf "$key_file" | awk '{print $4}')
            
            echo -e "${GREEN}🏷️  Serviço: $service${NC}"
            echo -e "   📧 Email: $email"
            echo -e "   🔑 Tipo: $key_type"
            echo -e "   📁 Arquivo: $key_file"
            echo -e "   🕐 Criada: $created"
            echo ""
        fi
    done
    
    echo -e "${BLUE}🔧 Entradas no arquivo config:${NC}"
    grep "^Host " "$CONFIG_FILE" | head -10 || echo -e "${YELLOW}Nenhuma entrada encontrada${NC}"
    
    echo -e "${BLUE}👤 Chaves no SSH Agent:${NC}"
    ssh-add -l 2>/dev/null || echo -e "${YELLOW}SSH Agent não está rodando ou não tem chaves${NC}"
}

test_connection() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo -e "${RED}Erro: Especifique o serviço para testar${NC}"
        return 1
    fi
    
    local host=""
    case $service in
        "github")
            host="github.com"
            ;;
        "gitlab")
            host="gitlab.com"
            ;;
        "bitbucket")
            host="bitbucket.org"
            ;;
        *)
            host="$service.com"
            ;;
    esac
    
    echo -e "${BLUE}🧪 Testando conexão com $service...${NC}"
    
    local key_file="$KEYS_DIR/id_${service}"
    if [ ! -f "$key_file" ]; then
        echo -e "${RED}❌ Chave não encontrada: $key_file${NC}"
        return 1
    fi
    
    add_key_to_agent "$service"
    
    echo -e "${YELLOW}Executando: ssh -T git@$host${NC}"
    local result=$(ssh -T git@$host 2>&1)
    
    if echo "$result" | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ CONEXÃO BEM-SUCEDIDA com $service!${NC}"
        echo -e "${GREEN}✓ Tudo configurado corretamente!${NC}"
    elif echo "$result" | grep -q "Permission denied"; then
        echo -e "${RED}❌ FALHA na autenticação com $service${NC}"
        echo -e "${YELLOW}⚠  Possíveis causas:${NC}"
        echo -e "   • Chave pública não foi adicionada ao $service"
        echo -e "   • Chave incorreta no $service"
        echo -e "   • Problema de permissões"
        echo -e "${YELLOW}📝 Soluções:${NC}"
        echo -e "   • Execute: $0 diagnose $service"
        echo -e "   • Verifique se a chave pública foi adicionada corretamente"
        echo -e "   • URL: https://$host/settings/keys"
    else
        echo -e "${YELLOW}📝 Resultado: $result${NC}"
    fi
}

diagnose_connection() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo -e "${RED}Erro: Especifique o serviço para diagnóstico${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔍 DIAGNÓSTICO DETALHADO para $service${NC}"
    echo ""
    
    local key_file="$KEYS_DIR/id_${service}"
    local pub_file="${key_file}.pub"
    
    echo -e "${YELLOW}1. 📁 VERIFICANDO ARQUIVOS:${NC}"
    if [ -f "$key_file" ]; then
        echo -e "   ✅ Chave privada: $key_file"
        ls -la "$key_file"
    else
        echo -e "   ❌ Chave privada NÃO encontrada: $key_file"
    fi
    
    if [ -f "$pub_file" ]; then
        echo -e "   ✅ Chave pública: $pub_file"
        ls -la "$pub_file"
    else
        echo -e "   ❌ Chave pública NÃO encontrada: $pub_file"
    fi
    echo ""
    
    echo -e "${YELLOW}2. 🔐 VERIFICANDO PERMISSÕES:${NC}"
    local key_perm=$(stat -c "%a" "$key_file" 2>/dev/null || echo "missing")
    local pub_perm=$(stat -c "%a" "$pub_file" 2>/dev/null || echo "missing")
    
    if [ "$key_perm" = "600" ]; then
        echo -e "   ✅ Permissão da chave privada: 600 (correta)"
    else
        echo -e "   ❌ Permissão da chave privada: $key_perm (deveria ser 600)"
        echo -e "   💡 Execute: chmod 600 $key_file"
    fi
    
    if [ "$pub_perm" = "644" ]; then
        echo -e "   ✅ Permissão da chave pública: 644 (correta)"
    else
        echo -e "   ❌ Permissão da chave pública: $pub_perm (deveria ser 644)"
        echo -e "   💡 Execute: chmod 644 $pub_file"
    fi
    echo ""
    
    echo -e "${YELLOW}3. ⚙️ VERIFICANDO CONFIGURAÇÃO SSH:${NC}"
    grep -A 5 "Host $service" "$CONFIG_FILE" || echo -e "   ❌ Configuração não encontrada para $service"
    echo ""
    
    echo -e "${YELLOW}4. 👤 VERIFICANDO SSH AGENT:${NC}"
    ssh-add -l | grep -i "$(ssh-keygen -lf "$key_file" 2>/dev/null | awk '{print $2}')" && \
        echo -e "   ✅ Chave está no SSH Agent" || \
        echo -e "   ❌ Chave NÃO está no SSH Agent"
    echo ""
    
    echo -e "${YELLOW}5. 🧪 TESTE FINAL DE CONEXÃO:${NC}"
    test_connection "$service"
}

delete_key() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo -e "${RED}Erro: Especifique o serviço para deletar${NC}"
        return 1
    fi
    
    local key_file="$KEYS_DIR/id_${service}"
    local pub_file="${key_file}.pub"
    
    if [ ! -f "$key_file" ]; then
        echo -e "${RED}Erro: Chave para $service não encontrada${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⚠  ATENÇÃO: Esta ação irá remover:${NC}"
    echo "   • $key_file"
    echo "   • $pub_file"
    echo "   • Entrada no arquivo config"
    
    read -p "❓ Tem certeza que deseja continuar? (s/N): " confirm
    if [[ ! $confirm =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Operação cancelada${NC}"
        return 1
    fi
    
    ssh-add -d "$key_file" 2>/dev/null
    
    rm -f "$key_file" "$pub_file"
    
    sed -i.bak "/^# $service - START/,/^# $service - END/d" "$CONFIG_FILE" 2>/dev/null
    
    echo -e "${GREEN}✅ Chave para $service removida com sucesso${NC}"
}

backup_keys() {
    local backup_file="ssh-keys-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    echo -e "${BLUE}📦 Criando backup das chaves...${NC}"
    
    if [ -d "$KEYS_DIR" ] && [ -n "$(ls -A "$KEYS_DIR" 2>/dev/null)" ]; then
        tar -czf "$backup_file" -C "$SSH_DIR" keys config known_hosts 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Backup criado: $backup_file${NC}"
            echo -e "${YELLOW}⚠  GUARDE ESTE ARQUIVO EM LOCAL SEGURO!${NC}"
            ls -lh "$backup_file"
        else
            echo -e "${RED}❌ Erro ao criar backup${NC}"
        fi
    else
        echo -e "${YELLOW}Nenhuma chave encontrada para backup${NC}"
    fi
}

restore_keys() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}Erro: Especifique o arquivo de backup${NC}"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Erro: Arquivo de backup não encontrado: $backup_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔄 Restaurando chaves do backup...${NC}"
    
    tar -xzf "$backup_file" -C "$SSH_DIR"
    
    if [ $? -eq 0 ]; then
        chmod 700 "$KEYS_DIR"
        chmod 600 "$CONFIG_FILE"
        find "$KEYS_DIR" -name "id_*" -type f ! -name "*.pub" -exec chmod 600 {} \;
        find "$KEYS_DIR" -name "*.pub" -exec chmod 644 {} \;
        
        start_ssh_agent
        echo -e "${GREEN}✅ Backup restaurado com sucesso${NC}"
        echo -e "${YELLOW}💡 Execute '$0 list' para ver as chaves restauradas${NC}"
    else
        echo -e "${RED}❌ Erro ao restaurar backup${NC}"
    fi
}

main() {
    echo -e "${BLUE}🚀 SSH Key Manager - Iniciando...${NC}"
    echo ""
    
    init_directories
    start_ssh_agent
    
    case $1 in
        "create")
            create_key "$2" "$3"
            ;;
        "list")
            list_keys
            ;;
        "test")
            test_connection "$2"
            ;;
        "delete")
            delete_key "$2"
            ;;
        "backup")
            backup_keys
            ;;
        "restore")
            restore_keys "$2"
            ;;
        "diagnose")
            diagnose_connection "$2"
            ;;
        *)
            show_usage
            ;;
    esac
}

main "$@"