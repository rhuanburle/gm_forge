# Branch Rules

Padrão de nomenclatura de branches para o projeto.

## Formato

`type/description`

## Types

- `feature/`: Novas funcionalidades.
- `bugfix/`: Correção de erros.
- `hotfix/`: Correções críticas em produção.
- `test/`: Branches de teste ou experimentação.
- `refactor/`: Refatorações grandes.

## Description

- Use `kebab-case` (letras minúsculas e hífens).
- Seja descritivo, mas conciso.

## Exemplos

```bash
feature/add-adventure-map
bugfix/fix-login-error
refactor/extract-widgets
test/riverpod-experiment
```

## Fluxo

1. Sempre crie a branch a partir da `main` (ou `develop` se existir).
2. Faça PR para a `main` ao finalizar.
3. Delete a branch após o merge.
