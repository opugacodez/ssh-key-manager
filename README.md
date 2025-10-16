# SSH Key Manager 🔑

Um script Bash completo para gerenciar múltiplas chaves SSH de forma organizada e eficiente.
## ✨ Características

- 🚀 **Criação fácil** de chaves SSH para múltiplos serviços
- 🗂️ **Organização automática** em diretório separado
- 🔐 **Gestão segura** de permissões
- 🔍 **Diagnóstico completo** para troubleshooting
- 💾 **Backup e restore** das chaves
- 🎯 **Multi-plataforma** (Linux, macOS, WSL)
- 🎨 **Interface colorida** e amigável

## 📦 Instalação

```bash
# Clone o repositório
git clone https://github.com/opugacodez/ssh-key-manager.git
cd ssh-key-manager

# Torne o script executável
chmod +x ssh-key-manager.sh

# Opcional: Mover para PATH global
sudo mv ssh-key-manager.sh /usr/local/bin/ssh-key-manager
```

## 🚀 Uso Rápido

### Criar uma chave para GitHub:
```bash
./ssh-key-manager.sh create github seu-email@gmail.com
```

### Criar uma chave para GitLab:
```bash
./ssh-key-manager.sh create gitlab seu-email@empresa.com
```

### Testar conexão:
```bash
./ssh-key-manager.sh test github
```

## 📋 Comandos Disponíveis

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `create` | Cria nova chave SSH | `./ssh-key-manager.sh create github email@exemplo.com` |
| `list` | Lista todas as chaves | `./ssh-key-manager.sh list` |
| `test` | Testa conexão com serviço | `./ssh-key-manager.sh test github` |
| `diagnose` | Diagnóstico detalhado | `./ssh-key-manager.sh diagnose github` |
| `delete` | Remove chave | `./ssh-key-manager.sh delete github` |
| `backup` | Backup das chaves | `./ssh-key-manager.sh backup` |
| `restore` | Restaura backup | `./ssh-key-manager.sh restore backup-file.tar.gz` |

## 🛠️ Serviços Suportados

- ✅ **GitHub** (`github`)
- ✅ **GitLab** (`gitlab`) 
- ✅ **Bitbucket** (`bitbucket`)
- ✅ **Serviços Customizados** (qualquer serviço SSH)

## 📁 Estrutura do Projeto

```
~/.ssh/
├── keys/                 # Diretório das chaves
│   ├── id_github        # Chave privada GitHub
│   ├── id_github.pub    # Chave pública GitHub
│   ├── id_gitlab        # Chave privada GitLab
│   └── id_gitlab.pub    # Chave pública GitLab
├── config               # Configuração SSH (gerenciado)
└── known_hosts         # Hosts conhecidos
```

## 🔧 Fluxo de Trabalho Completo

### 1. Criar Chave para GitHub
```bash
./ssh-key-manager.sh create github richardpuga2002@gmail.com
```

### 2. Copiar Chave Pública
📋 O script automaticamente mostra a chave pública e tenta copiar para clipboard.

### 3. Adicionar ao GitHub
🌐 Acesse: https://github.com/settings/ssh/new
- Cole a chave pública
- Dê um título descritivo
- Clique "Add SSH key"

### 4. Testar Conexão
```bash
./ssh-key-manager.sh test github
```

### ✅ Deverá ver:
```
✅ CONEXÃO BEM-SUCEDIDA com github!
✓ Tudo configurado corretamente!
```

## 🐛 Solução de Problemas

### Se a conexão falhar:

**1. Use o diagnóstico:**
```bash
./ssh-key-manager.sh diagnose github
```

**2. Verifique manualmente:**
- A chave pública foi adicionada corretamente no serviço?
- As permissões dos arquivos estão corretas?
- O SSH agent está rodando?

**3. URLs para adicionar chaves:**
- GitHub: https://github.com/settings/ssh/new
- GitLab: https://gitlab.com/-/profile/keys  
- Bitbucket: https://bitbucket.org/account/settings/ssh-keys/

## 🔒 Segurança

- ✅ Permissões automáticas (600 para chaves privadas, 644 para públicas)
- ✅ Diretório seguro com permissões 700
- ✅ Configuração SSH otimizada
- ✅ Backup criptografado opcional

## 📝 Exemplos Completos

### Trabalhando com Múltiplos Serviços:
```bash
# Criar chave para trabalho
./ssh-key-manager.sh create github richard@empresa.com

# Criar chave para projetos pessoais  
./ssh-key-manager.sh create gitlab richardpuga2002@gmail.com

# Criar chave para cliente específico
./ssh-key-manager.sh create bitbucket richard@cliente.com

# Listar todas as chaves
./ssh-key-manager.sh list
```

### Backup e Restore:
```bash
# Fazer backup
./ssh-key-manager.sh backup

# Restaurar backup
./ssh-key-manager.sh restore ssh-keys-backup-20231201-143022.tar.gz
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## ⚠️ Aviso Legal

Este script gerencia chaves SSH sensíveis. Sempre:
- Mantenha backups seguros
- Use passphrases fortes quando possível
- Revogue chaves não utilizadas
- Monitore o acesso aos seus repositórios

---

**Feito com ❤️ para a comunidade de desenvolvedores**

Se este projeto te ajudou, considere dar uma ⭐ no repositório!