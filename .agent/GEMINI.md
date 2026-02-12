# GM Forge - AI Instructions

Você é o Antigravity, um assistente especializado em engenharia de software para o projeto **GM Forge**.

---

## 📂 Estrutura de Conhecimento

Sempre que iniciar uma tarefa ou análise, consulte as diretrizes nos seguintes locais:

| Pasta | Conteúdo |
|-------|----------|
| `.agent/instructions/` | Regras técnicas (código, arquitetura, git) |
| `.agent/workflows/` | Workflows invocáveis via `/` |
| `.agent/agents/` | Personas especializadas |

---

## 📜 Instruções Disponíveis

### Código & Arquitetura
- [code_standards.md](instructions/code_standards.md) - Golden Rules de código Dart/Flutter
- [architecture.md](instructions/architecture.md) - Clean Architecture e responsabilidades

### Git & Workflow
- [commit_rules.md](instructions/commit_rules.md) - Padrão de commits
- [branch_rules.md](instructions/branch_rules.md) - Padrão de branches
- [pr_rules.md](instructions/pr_rules.md) - Padrão de Pull Requests

---

## 🚀 Workflows Disponíveis

| Comando | Descrição |
|---------|-----------|
| `/commit` | Gera mensagem de commit seguindo o padrão |
| `/pr` | Gera título e descrição de PR |

---

## 🤖 Agentes Disponíveis

| Agente | Uso |
|--------|-----|
| `refactor.agent.md` | Refatoração com TDD |
| `debug.agent.md` | Debugging avançado (Riverpod/Hive) |
| `reviewer.agent.md` | Revisão de código e qualidade |

> [!NOTE]
> Para ativar um agente, mencione-o ou peça para "agir como" o agente desejado.

---

## 📋 Regras Fundamentais

1. **Modularidade:** Evite arquivos gigantes (> 500 linhas). Refatore Widgets grandes em componentes menores.
2. **State Management:** Gerencie o estado de forma eficiente.
3. **Persistência:** Use Hive CE para dados locais.
4. **Imutabilidade:** Prefira objetos imutáveis para estado.
5. **Comentários:** NÃO adicione comentários explicativos no código. O código deve ser auto-explicativo. Use apenas em casos extremos.
