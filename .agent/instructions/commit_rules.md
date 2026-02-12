# Commit Rules

Siga o padrão **Conventional Commits** para mensagens de commit.

## Formato

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

- `feat`: Nova funcionalidade.
- `fix`: Correção de bug.
- `docs`: Alterações apenas em documentação.
- `style`: Formatação, pontos e vírgulas, etc (não altera código de produção).
- `refactor`: Refatoração de código (sem fix ou feat).
- `perf`: Melhoria de performance.
- `test`: Adição ou correção de testes.
- `chor`: Atualização de tarefas de build, configs, etc.

## Scopes (Opcional)

Use o nome da feature ou módulo afetado.
- `adventure`
- `auth`
- `ui`
- `database`

## Exemplos

```bash
feat(adventure): add support for dungeon map image
fix(auth): resolve logout crash on web
refactor(ui): extract AdventureCard widget
docs: update architecture diagram
```

## Regras Importantes

1. Use o imperativo no subject ("add" e não "added").
2. Não termine o subject com ponto.
3. Use o body para explicar **o que** e **por que** mudou.
